import 'package:flutter/material.dart';

/// Supported course names (mirrors the React Native app's CourseName enum)
enum CourseName {
  spanish,
  arabic,
  turkish,
  german,
  greek,
  italian,
  swahili,
  french,
  ingles,
  music,
}

extension CourseNameExtension on CourseName {
  String get value {
    switch (this) {
      case CourseName.spanish:
        return 'spanish';
      case CourseName.arabic:
        return 'arabic';
      case CourseName.turkish:
        return 'turkish';
      case CourseName.german:
        return 'german';
      case CourseName.greek:
        return 'greek';
      case CourseName.italian:
        return 'italian';
      case CourseName.swahili:
        return 'swahili';
      case CourseName.french:
        return 'french';
      case CourseName.ingles:
        return 'ingles';
      case CourseName.music:
        return 'music';
    }
  }

  static CourseName? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'spanish':
        return CourseName.spanish;
      case 'arabic':
        return CourseName.arabic;
      case 'turkish':
        return CourseName.turkish;
      case 'german':
        return CourseName.german;
      case 'greek':
        return CourseName.greek;
      case 'italian':
        return CourseName.italian;
      case 'swahili':
        return CourseName.swahili;
      case 'french':
        return CourseName.french;
      case 'ingles':
        return CourseName.ingles;
      case 'music':
        return CourseName.music;
      default:
        return null;
    }
  }
}

enum CourseType { intro, complete }

/// UI colour palette per course
class UIColors {
  const UIColors({
    required this.background,
    required this.softBackground,
    required this.textOnBackground,
    required this.backgroundAccent,
  });

  final Color background;
  final Color softBackground;
  final Color textOnBackground; // Colors.white or Colors.black
  final Color backgroundAccent;

  // Convenience: whether text should be light
  bool get isDark => textOnBackground == Colors.white;
}

/// Static metadata for each course (images, colours, titles)
class CourseInfo {
  const CourseInfo({
    required this.name,
    required this.shortTitle,
    required this.fullTitle,
    required this.courseType,
    required this.fallbackLessonCount,
    required this.uiColors,
    this.imageAsset,
  });

  final CourseName name;
  final String shortTitle;
  final String fullTitle;
  final CourseType courseType;
  final String fallbackLessonCount;
  final UIColors uiColors;
  final String? imageAsset; // local asset path (may be null until assets added)
}

/// A pointer to a content-addressed file (mirrors FilePointer in RN app)
class FilePointer {
  const FilePointer({
    required this.object,
    required this.filesize,
    required this.mimeType,
  });

  final String object; // content-addressed hash
  final int filesize;
  final String mimeType;

  factory FilePointer.fromJson(Map<String, dynamic> json) {
    return FilePointer(
      object: json['object'] as String,
      filesize: json['filesize'] as int,
      mimeType: json['mimeType'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        '_type': 'file',
        'object': object,
        'filesize': filesize,
        'mimeType': mimeType,
      };
}

/// Quality selection (high or low bitrate)
enum AudioQuality { high, low }

/// Lesson variants (high + low quality file pointers)
class LessonVariants {
  const LessonVariants({required this.hq, required this.lq});

  final FilePointer hq;
  final FilePointer lq;

  factory LessonVariants.fromJson(Map<String, dynamic> json) {
    return LessonVariants(
      hq: FilePointer.fromJson(json['hq'] as Map<String, dynamic>),
      lq: FilePointer.fromJson(json['lq'] as Map<String, dynamic>),
    );
  }
}

/// Individual lesson data (mirrors LessonData in RN app)
class LessonData {
  const LessonData({
    required this.id,
    required this.title,
    required this.duration,
    required this.variants,
  });

  final String id;
  final String title;
  final int duration; // seconds
  final LessonVariants variants;

  FilePointer pointer(AudioQuality quality) =>
      quality == AudioQuality.high ? variants.hq : variants.lq;

  factory LessonData.fromJson(Map<String, dynamic> json) {
    return LessonData(
      id: json['id'] as String,
      title: json['title'] as String,
      duration: json['duration'] as int,
      variants:
          LessonVariants.fromJson(json['variants'] as Map<String, dynamic>),
    );
  }
}

/// Course metadata (mirrors CourseMetadata in RN app)
class CourseMetadata {
  const CourseMetadata({
    required this.buildVersion,
    required this.lessons,
  });

  final int buildVersion;
  final List<LessonData> lessons;

  factory CourseMetadata.fromJson(Map<String, dynamic> json) {
    final lessonsList = (json['lessons'] as List<dynamic>)
        .map((e) => LessonData.fromJson(e as Map<String, dynamic>))
        .toList();
    return CourseMetadata(
      buildVersion: json['buildVersion'] as int,
      lessons: lessonsList,
    );
  }
}

/// Course index entry (from the remote all-courses.json)
class CourseIndexEntry {
  const CourseIndexEntry({
    required this.id,
    required this.meta,
    required this.lessonCount,
  });

  final String id;
  final FilePointer meta;
  final int lessonCount;

  factory CourseIndexEntry.fromJson(Map<String, dynamic> json) {
    return CourseIndexEntry(
      id: json['id'] as String,
      meta: FilePointer.fromJson(json['meta'] as Map<String, dynamic>),
      lessonCount: json['lessons'] as int,
    );
  }
}

/// The top-level course index (from all-courses.json)
class CourseIndex {
  const CourseIndex({
    required this.buildVersion,
    required this.casBaseUrl,
    required this.courses,
  });

  final int buildVersion;
  final String casBaseUrl;
  final List<CourseIndexEntry> courses;

  factory CourseIndex.fromJson(Map<String, dynamic> json) {
    final coursesList = (json['courses'] as List<dynamic>)
        .map((e) => CourseIndexEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return CourseIndex(
      buildVersion: json['buildVersion'] as int,
      casBaseUrl: json['casBaseURL'] as String,
      courses: coursesList,
    );
  }
}
