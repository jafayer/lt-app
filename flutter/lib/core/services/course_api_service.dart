import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/course.dart';
import 'storage_service.dart';

/// Fetches the remote course index and per-course metadata.
/// Results are cached in [StorageService] for 7 days.
class CourseApiService {
  CourseApiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  // ---------------------------------------------------------------------------
  // Course index
  // ---------------------------------------------------------------------------

  Future<CourseIndex> fetchCourseIndex({bool forceRemote = false}) async {
    if (!forceRemote) {
      final cached = await StorageService.instance.getCachedCourseIndex();
      if (cached != null) {
        return CourseIndex.fromJson(cached);
      }
    }

    final response = await _dio.get<Map<String, dynamic>>(
      'https://downloads.languagetransfer.org/all-courses.json',
    );
    final data = response.data!;
    await StorageService.instance.cacheCourseIndex(data);
    return CourseIndex.fromJson(data);
  }

  // ---------------------------------------------------------------------------
  // Per-course metadata
  // ---------------------------------------------------------------------------

  Future<CourseMetadata> fetchCourseMetadata(
    String casBaseUrl,
    FilePointer metaPointer,
  ) async {
    final url = '$casBaseUrl/${metaPointer.object}';
    final response = await _dio.get<Map<String, dynamic>>(url);
    return CourseMetadata.fromJson(response.data!);
  }

  // ---------------------------------------------------------------------------
  // Build a streaming / direct URL for a lesson
  // ---------------------------------------------------------------------------

  String getLessonUrl(String casBaseUrl, FilePointer pointer) {
    return '$casBaseUrl/${pointer.object}';
  }

  // ---------------------------------------------------------------------------
  // Download a file to [savePath] (mobile only; web streams directly)
  // ---------------------------------------------------------------------------

  Future<void> downloadFile(
    String url,
    String savePath, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    );
  }
}
