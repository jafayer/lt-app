import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../models/progress.dart';
import '../services/storage_service.dart';

// ---------------------------------------------------------------------------
// Progress per-lesson provider
// ---------------------------------------------------------------------------

/// Family provider: returns progress for a specific (course, lessonIndex).
final lessonProgressProvider = AsyncNotifierProviderFamily<
    LessonProgressNotifier, LessonProgress, ({String course, int lesson})>(
  LessonProgressNotifier.new,
);

class LessonProgressNotifier
    extends FamilyAsyncNotifier<LessonProgress, ({String course, int lesson})> {
  @override
  Future<LessonProgress> build(({String course, int lesson}) arg) async {
    return StorageService.instance
        .getLessonProgress(arg.course, arg.lesson);
  }

  Future<void> saveProgress(double position) async {
    final current = state.valueOrNull ?? LessonProgress.empty;
    final updated = current.copyWith(position: position, finished: current.finished);
    await StorageService.instance
        .saveLessonProgress(arg.course, arg.lesson, updated);
    state = AsyncValue.data(updated);
  }

  Future<void> markFinished() async {
    final updated = const LessonProgress(finished: true, position: null);
    await StorageService.instance
        .saveLessonProgress(arg.course, arg.lesson, updated);
    state = AsyncValue.data(updated);
  }

  Future<void> resetProgress() async {
    const updated = LessonProgress.empty;
    await StorageService.instance
        .saveLessonProgress(arg.course, arg.lesson, updated);
    state = const AsyncValue.data(LessonProgress.empty);
  }
}

// ---------------------------------------------------------------------------
// Most-recently-played tracking
// ---------------------------------------------------------------------------

final mostRecentCourseProvider =
    AsyncNotifierProvider<MostRecentCourseNotifier, CourseName?>(
  MostRecentCourseNotifier.new,
);

class MostRecentCourseNotifier extends AsyncNotifier<CourseName?> {
  @override
  Future<CourseName?> build() =>
      StorageService.instance.getMostRecentCourse();

  Future<void> save(CourseName course) async {
    await StorageService.instance.saveMostRecentCourse(course);
    state = AsyncValue.data(course);
  }
}

final mostRecentLessonProvider =
    AsyncNotifierProviderFamily<MostRecentLessonNotifier, int?, String>(
  MostRecentLessonNotifier.new,
);

class MostRecentLessonNotifier
    extends FamilyAsyncNotifier<int?, String> {
  @override
  Future<int?> build(String arg) =>
      StorageService.instance.getMostRecentLesson(arg);

  Future<void> save(int lessonIndex) async {
    await StorageService.instance.saveMostRecentLesson(arg, lessonIndex);
    state = AsyncValue.data(lessonIndex);
  }
}
