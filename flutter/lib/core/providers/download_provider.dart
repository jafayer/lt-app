import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/download.dart';
import '../models/course.dart';
import '../services/download_manager.dart';
import 'settings_provider.dart';

// ---------------------------------------------------------------------------
// Download snapshot stream → notifier
// ---------------------------------------------------------------------------

final downloadSnapshotsProvider =
    StreamNotifierProvider<DownloadSnapshotsNotifier,
        Map<String, DownloadSnapshot>>(
  DownloadSnapshotsNotifier.new,
);

class DownloadSnapshotsNotifier
    extends StreamNotifier<Map<String, DownloadSnapshot>> {
  @override
  Stream<Map<String, DownloadSnapshot>> build() {
    return DownloadManager.instance.snapshotsStream;
  }
}

// ---------------------------------------------------------------------------
// Per-lesson download snapshot convenience provider
// ---------------------------------------------------------------------------

final lessonDownloadProvider =
    Provider.family<DownloadSnapshot, ({String course, int lesson})>((ref, arg) {
  final snapshots = ref.watch(downloadSnapshotsProvider).valueOrNull ?? {};
  final key = '${arg.course}/${arg.lesson}';
  return snapshots[key] ??
      DownloadSnapshot(id: key, state: DownloadState.idle);
});

// ---------------------------------------------------------------------------
// Download action helpers
// ---------------------------------------------------------------------------

final downloadActionsProvider = Provider<DownloadActions>((ref) {
  return DownloadActions(ref);
});

class DownloadActions {
  const DownloadActions(this._ref);
  final Ref _ref;

  Future<void> download({
    required String course,
    required int lessonIndex,
    required LessonData lesson,
    required String casBaseUrl,
  }) async {
    final settings = _ref.read(settingsProvider).valueOrNull;
    final quality = settings?.downloadQuality == 'low'
        ? AudioQuality.low
        : AudioQuality.high;
    final pointer = lesson.pointer(quality);
    final url = '$casBaseUrl/${pointer.object}';

    await DownloadManager.instance.requestDownload(
      course: course,
      lessonIndex: lessonIndex,
      objectHash: pointer.object,
      url: url,
      totalBytes: pointer.filesize,
    );
  }

  Future<void> remove({
    required String course,
    required int lessonIndex,
    required LessonData lesson,
  }) async {
    final settings = _ref.read(settingsProvider).valueOrNull;
    final quality = settings?.downloadQuality == 'low'
        ? AudioQuality.low
        : AudioQuality.high;
    final pointer = lesson.pointer(quality);
    await DownloadManager.instance.removeDownload(
      course: course,
      lessonIndex: lessonIndex,
      objectHash: pointer.object,
    );
  }
}
