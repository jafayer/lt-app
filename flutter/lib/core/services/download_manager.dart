import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/course.dart';
import '../models/download.dart';
import 'storage_service.dart';

/// Manages audio file downloads.
///
/// On mobile (Android/iOS): downloads are saved to the app's documents directory
///   at `objects/{objectHash}`. The same content-addressed scheme as the RN app.
///
/// On web: downloads are not persisted to disk (browsers restrict this).
///   The download status is tracked in memory and audio streams directly.
class DownloadManager {
  DownloadManager._();

  static DownloadManager? _instance;
  static DownloadManager get instance => _instance ??= DownloadManager._();

  final Dio _dio = Dio();

  // In-memory snapshot store keyed by "course/lessonIndex"
  final Map<String, DownloadSnapshot> _snapshots = {};

  // Active cancel tokens for in-progress downloads
  final Map<String, CancelToken> _cancelTokens = {};

  // Controller to broadcast snapshot changes
  final _snapshotController =
      StreamController<Map<String, DownloadSnapshot>>.broadcast();

  Stream<Map<String, DownloadSnapshot>> get snapshotsStream =>
      _snapshotController.stream;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Call once at startup to restore download state and clean staging area.
  Future<void> init() async {
    if (kIsWeb) return; // nothing to restore on web
    await _cleanStagingDirectory();
    await _restoreDownloadedFiles();
  }

  Future<void> _cleanStagingDirectory() async {
    try {
      final staging = await _stagingDir();
      if (await staging.exists()) {
        await for (final entity in staging.list()) {
          await entity.delete();
        }
      }
    } catch (_) {}
  }

  Future<void> _restoreDownloadedFiles() async {
    try {
      final objects = await _objectsDir();
      if (!await objects.exists()) return;
      await for (final entity in objects.list()) {
        if (entity is File) {
          final id = entity.path.split('/').last;
          _snapshots[id] = DownloadSnapshot(
            id: id,
            state: DownloadState.finished,
            bytesWritten: await entity.length(),
            totalBytes: await entity.length(),
          );
        }
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Directory helpers (mobile only)
  // ---------------------------------------------------------------------------

  Future<Directory> _objectsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/objects');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _stagingDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/staging');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _objectFile(String objectHash) async {
    final dir = await _objectsDir();
    return File('${dir.path}/$objectHash');
  }

  Future<File> _stagingFile(String objectHash) async {
    final dir = await _stagingDir();
    return File('${dir.path}/$objectHash.download');
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  String _key(String course, int lesson) => '$course/$lesson';

  DownloadSnapshot getSnapshot(String course, int lesson) {
    return _snapshots[_key(course, lesson)] ??
        DownloadSnapshot(
          id: _key(course, lesson),
          state: DownloadState.idle,
        );
  }

  bool isDownloaded(String course, int lesson) {
    return getSnapshot(course, lesson).state == DownloadState.finished;
  }

  /// Returns the local file path for a downloaded lesson (mobile only).
  Future<String?> getLocalPath(String objectHash) async {
    if (kIsWeb) return null;
    final file = await _objectFile(objectHash);
    if (await file.exists()) return file.path;
    return null;
  }

  /// Request a download for a specific lesson.
  Future<void> requestDownload({
    required String course,
    required int lessonIndex,
    required String objectHash,
    required String url,
    required int totalBytes,
  }) async {
    final key = _key(course, lessonIndex);

    if (kIsWeb) {
      // Web: mark as finished immediately since we stream from the network
      _snapshots[key] = DownloadSnapshot(
        id: key,
        state: DownloadState.finished,
        bytesWritten: totalBytes,
        totalBytes: totalBytes,
      );
      _notify();
      return;
    }

    // Check if already downloaded
    final file = await _objectFile(objectHash);
    if (await file.exists()) {
      _snapshots[key] = DownloadSnapshot(
        id: key,
        state: DownloadState.finished,
        bytesWritten: totalBytes,
        totalBytes: totalBytes,
      );
      _notify();
      await StorageService.instance.setDownloadIntent(
          course, lessonIndex, true);
      return;
    }

    // Mark as requested
    _snapshots[key] = DownloadSnapshot(
      id: key,
      state: DownloadState.requested,
      totalBytes: totalBytes,
    );
    _notify();
    await StorageService.instance.setDownloadIntent(course, lessonIndex, true);

    // Start download
    _startDownload(
      key: key,
      course: course,
      lessonIndex: lessonIndex,
      objectHash: objectHash,
      url: url,
      totalBytes: totalBytes,
    );
  }

  void _startDownload({
    required String key,
    required String course,
    required int lessonIndex,
    required String objectHash,
    required String url,
    required int totalBytes,
  }) {
    final cancelToken = CancelToken();
    _cancelTokens[key] = cancelToken;

    _snapshots[key] = DownloadSnapshot(
      id: key,
      state: DownloadState.downloading,
      totalBytes: totalBytes,
    );
    _notify();

    _performDownload(
      key: key,
      course: course,
      lessonIndex: lessonIndex,
      objectHash: objectHash,
      url: url,
      totalBytes: totalBytes,
      cancelToken: cancelToken,
    ).ignore();
  }

  Future<void> _performDownload({
    required String key,
    required String course,
    required int lessonIndex,
    required String objectHash,
    required String url,
    required int totalBytes,
    required CancelToken cancelToken,
  }) async {
    try {
      final staging = await _stagingFile(objectHash);
      await _dio.download(
        url,
        staging.path,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          _snapshots[key] = DownloadSnapshot(
            id: key,
            state: DownloadState.downloading,
            bytesWritten: received,
            totalBytes: total > 0 ? total : totalBytes,
          );
          _notify();
        },
      );

      // Atomic rename from staging to objects
      final dest = await _objectFile(objectHash);
      await staging.rename(dest.path);

      _snapshots[key] = DownloadSnapshot(
        id: key,
        state: DownloadState.finished,
        bytesWritten: totalBytes,
        totalBytes: totalBytes,
      );
      _notify();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _snapshots[key] = DownloadSnapshot(
          id: key,
          state: DownloadState.idle,
        );
      } else {
        _snapshots[key] = DownloadSnapshot(
          id: key,
          state: DownloadState.error,
          errorMessage: e.message,
        );
      }
      _notify();
    } catch (e) {
      _snapshots[key] = DownloadSnapshot(
        id: key,
        state: DownloadState.error,
        errorMessage: e.toString(),
      );
      _notify();
    } finally {
      _cancelTokens.remove(key);
    }
  }

  /// Cancel and remove a downloaded lesson.
  Future<void> removeDownload({
    required String course,
    required int lessonIndex,
    required String objectHash,
  }) async {
    final key = _key(course, lessonIndex);

    // Cancel in-progress download
    _cancelTokens[key]?.cancel('User cancelled');
    _cancelTokens.remove(key);

    if (!kIsWeb) {
      try {
        final file = await _objectFile(objectHash);
        if (await file.exists()) await file.delete();
        final staging = await _stagingFile(objectHash);
        if (await staging.exists()) await staging.delete();
      } catch (_) {}
    }

    _snapshots.remove(key);
    _notify();
    await StorageService.instance.setDownloadIntent(course, lessonIndex, false);
  }

  /// Clear all downloads for a course.
  Future<void> removeCourseDownloads({
    required String course,
    required List<LessonData> lessons,
  }) async {
    for (var i = 0; i < lessons.length; i++) {
      final lesson = lessons[i];
      await removeDownload(
        course: course,
        lessonIndex: i,
        objectHash: lesson.variants.hq.object,
      );
    }
  }

  void _notify() {
    _snapshotController.add(Map.unmodifiable(_snapshots));
  }

  void dispose() {
    for (final t in _cancelTokens.values) {
      t.cancel('Disposed');
    }
    _snapshotController.close();
  }
}
