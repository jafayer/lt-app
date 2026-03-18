import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress.dart';
import '../models/course.dart';

/// Cross-platform storage service.
///
/// Uses [SharedPreferences] under the hood, which maps to:
///   - Android: SharedPreferences (XML)
///   - iOS:     NSUserDefaults
///   - Web:     localStorage
///
/// Key schema mirrors the React Native app:
///   @activity/{course}/{lesson}           → LessonProgress JSON
///   @activity/most-recent-course         → CourseName string
///   @activity/{course}/most-recent-lesson → lesson index (int as string)
///   @preferences/{name}                  → JSON-serialised value
///   @course-index/all                    → cached course index JSON + timestamp
class StorageService {
  StorageService._();

  static StorageService? _instance;
  static StorageService get instance => _instance!;

  late SharedPreferences _prefs;

  static Future<StorageService> init() async {
    _instance = StorageService._();
    _instance!._prefs = await SharedPreferences.getInstance();
    return _instance!;
  }

  // ---------------------------------------------------------------------------
  // Lesson progress
  // ---------------------------------------------------------------------------

  String _progressKey(String course, int lesson) =>
      '@activity/$course/$lesson';

  Future<LessonProgress> getLessonProgress(
      String course, int lessonIndex) async {
    final raw = _prefs.getString(_progressKey(course, lessonIndex));
    if (raw == null) return LessonProgress.empty;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return LessonProgress.fromJson(json);
    } catch (_) {
      return LessonProgress.empty;
    }
  }

  Future<void> saveLessonProgress(
      String course, int lessonIndex, LessonProgress progress) async {
    await _prefs.setString(
      _progressKey(course, lessonIndex),
      jsonEncode(progress.toJson()),
    );
  }

  // ---------------------------------------------------------------------------
  // Most-recent course / lesson
  // ---------------------------------------------------------------------------

  Future<CourseName?> getMostRecentCourse() async {
    final raw = _prefs.getString('@activity/most-recent-course');
    if (raw == null) return null;
    return CourseNameExtension.fromString(raw);
  }

  Future<void> saveMostRecentCourse(CourseName course) async {
    await _prefs.setString('@activity/most-recent-course', course.value);
  }

  Future<int?> getMostRecentLesson(String course) async {
    final raw = _prefs.getString('@activity/$course/most-recent-lesson');
    return raw == null ? null : int.tryParse(raw);
  }

  Future<void> saveMostRecentLesson(String course, int lessonIndex) async {
    await _prefs.setString(
        '@activity/$course/most-recent-lesson', '$lessonIndex');
  }

  // ---------------------------------------------------------------------------
  // App preferences
  // ---------------------------------------------------------------------------

  T? getPreference<T>(String name) {
    final raw = _prefs.getString('@preferences/$name');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as T;
    } catch (_) {
      return null;
    }
  }

  Future<void> setPreference<T>(String name, T value) async {
    await _prefs.setString('@preferences/$name', jsonEncode(value));
  }

  // ---------------------------------------------------------------------------
  // Course index cache
  // ---------------------------------------------------------------------------

  static const Duration _cacheMaxAge = Duration(days: 7);

  Future<Map<String, dynamic>?> getCachedCourseIndex() async {
    final raw = _prefs.getString('@course-index/all');
    if (raw == null) return null;
    try {
      final wrapper = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp = wrapper['timestamp'] as int?;
      if (timestamp == null) return null;
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
      if (age > _cacheMaxAge) return null;
      return wrapper['data'] as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheCourseIndex(Map<String, dynamic> data) async {
    await _prefs.setString(
      '@course-index/all',
      jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Download intent persistence
  // ---------------------------------------------------------------------------

  String _downloadIntentKey(String course, int lesson) =>
      '@download-intent/$course/$lesson';

  Future<bool> getDownloadIntent(String course, int lesson) async {
    return _prefs.getBool(_downloadIntentKey(course, lesson)) ?? false;
  }

  Future<void> setDownloadIntent(
      String course, int lesson, bool requested) async {
    await _prefs.setBool(_downloadIntentKey(course, lesson), requested);
  }

  Future<List<String>> getAllDownloadIntents() async {
    return _prefs
        .getKeys()
        .where((k) => k.startsWith('@download-intent/') && _prefs.getBool(k) == true)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Clear helpers
  // ---------------------------------------------------------------------------

  Future<void> clearAllProgress() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('@activity/'));
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  Future<void> clearAllDownloadIntents() async {
    final keys =
        _prefs.getKeys().where((k) => k.startsWith('@download-intent/'));
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
