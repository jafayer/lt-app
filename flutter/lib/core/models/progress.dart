/// Lesson progress (mirrors Progress in the RN app)
class LessonProgress {
  const LessonProgress({
    required this.finished,
    this.position, // seconds into the lesson, null if never played
  });

  final bool finished;
  final double? position;

  static const LessonProgress empty =
      LessonProgress(finished: false, position: null);

  LessonProgress copyWith({bool? finished, double? position}) {
    return LessonProgress(
      finished: finished ?? this.finished,
      position: position ?? this.position,
    );
  }

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      finished: json['finished'] as bool? ?? false,
      position: (json['progress'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'finished': finished,
        'progress': position,
      };
}
