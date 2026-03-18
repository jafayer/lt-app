import 'package:flutter/material.dart';
import '../models/course.dart';

/// Static course information, mirroring src/data/courseData.ts in the RN app.
/// The API URL and CAS base URL come from the remote course index.
const String kCourseIndexUrl =
    'https://downloads.languagetransfer.org/all-courses.json';

/// All available courses.
const List<CourseInfo> kAllCourses = [
  CourseInfo(
    name: CourseName.spanish,
    shortTitle: 'Spanish',
    fullTitle: 'Complete Spanish',
    courseType: CourseType.complete,
    fallbackLessonCount: '90',
    uiColors: _spanishColors,
  ),
  CourseInfo(
    name: CourseName.arabic,
    shortTitle: 'Arabic',
    fullTitle: 'Introduction to Arabic',
    courseType: CourseType.intro,
    fallbackLessonCount: '38',
    uiColors: _arabicColors,
  ),
  CourseInfo(
    name: CourseName.turkish,
    shortTitle: 'Turkish',
    fullTitle: 'Introduction to Turkish',
    courseType: CourseType.intro,
    fallbackLessonCount: '44',
    uiColors: _turkishColors,
  ),
  CourseInfo(
    name: CourseName.german,
    shortTitle: 'German',
    fullTitle: 'Complete German',
    courseType: CourseType.complete,
    fallbackLessonCount: '50',
    uiColors: _germanColors,
  ),
  CourseInfo(
    name: CourseName.greek,
    shortTitle: 'Greek',
    fullTitle: 'Complete Greek',
    courseType: CourseType.complete,
    fallbackLessonCount: '120',
    uiColors: _greekColors,
  ),
  CourseInfo(
    name: CourseName.italian,
    shortTitle: 'Italian',
    fullTitle: 'Introduction to Italian',
    courseType: CourseType.intro,
    fallbackLessonCount: '45',
    uiColors: _italianColors,
  ),
  CourseInfo(
    name: CourseName.swahili,
    shortTitle: 'Swahili',
    fullTitle: 'Complete Swahili',
    courseType: CourseType.complete,
    fallbackLessonCount: '110',
    uiColors: _swahiliColors,
  ),
  CourseInfo(
    name: CourseName.french,
    shortTitle: 'French',
    fullTitle: 'Introduction to French',
    courseType: CourseType.intro,
    fallbackLessonCount: '40',
    uiColors: _frenchColors,
  ),
  CourseInfo(
    name: CourseName.ingles,
    shortTitle: 'Inglés',
    fullTitle: 'Introduction to Inglés',
    courseType: CourseType.intro,
    fallbackLessonCount: '40',
    uiColors: _inglesColors,
  ),
  CourseInfo(
    name: CourseName.music,
    shortTitle: 'Music',
    fullTitle: 'Introduction to Music',
    courseType: CourseType.intro,
    fallbackLessonCount: '30',
    uiColors: _musicColors,
  ),
];

// ---------------------------------------------------------------------------
// Per-course colour constants (must be const for use in const constructors)
// ---------------------------------------------------------------------------

const _spanishColors = UIColors(
  background: Color(0xFF7186D0),
  softBackground: Color(0xFF8A9BD8),
  textOnBackground: Colors.white,
  backgroundAccent: Color(0xFF5570BB),
);

const _arabicColors = UIColors(
  background: Color(0xFFC2930F),
  softBackground: Color(0xFFD4A832),
  textOnBackground: Colors.white,
  backgroundAccent: Color(0xFFA07A0C),
);

const _turkishColors = UIColors(
  background: Color(0xFFA20B3B),
  softBackground: Color(0xFFBD2454),
  textOnBackground: Colors.white,
  backgroundAccent: Color(0xFF820930),
);

const _germanColors = UIColors(
  background: Color(0xFF009900),
  softBackground: Color(0xFF1AAA1A),
  textOnBackground: Colors.white,
  backgroundAccent: Color(0xFF007A00),
);

const _greekColors = UIColors(
  background: Color(0xFFD57D2F),
  softBackground: Color(0xFFDF9653),
  textOnBackground: Colors.white,
  backgroundAccent: Color(0xFFAE6424),
);

const _italianColors = UIColors(
  background: Color(0xFFE423AE),
  softBackground: Color(0xFFE94CBF),
  textOnBackground: Colors.white,
  backgroundAccent: Color(0xFFBB1D8C),
);

const _swahiliColors = UIColors(
  background: Color(0xFF12EDDD),
  softBackground: Color(0xFF3DF0E4),
  textOnBackground: Colors.black,
  backgroundAccent: Color(0xFF0EC0B3),
);

const _frenchColors = UIColors(
  background: Color(0xFF10BDFF),
  softBackground: Color(0xFF35C9FF),
  textOnBackground: Colors.black,
  backgroundAccent: Color(0xFF0D99D0),
);

const _inglesColors = UIColors(
  background: Color(0xFF7186D0),
  softBackground: Color(0xFF8A9BD8),
  textOnBackground: Colors.white,
  backgroundAccent: Color(0xFF5570BB),
);

const _musicColors = UIColors(
  background: Color(0xFFF8EEBC),
  softBackground: Color(0xFFFAF2CE),
  textOnBackground: Colors.black,
  backgroundAccent: Color(0xFFD4C990),
);

/// Lookup a [CourseInfo] by [CourseName].
CourseInfo getCourseInfo(CourseName name) {
  return kAllCourses.firstWhere((c) => c.name == name);
}

/// Format a duration in seconds to a human-readable string.
String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) {
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
  return '${m}m ${s.toString().padLeft(2, '0')}s';
}

/// Format bytes to a readable string (e.g. "24.5 MB").
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
