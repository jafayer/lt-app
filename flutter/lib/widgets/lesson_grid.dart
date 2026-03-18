import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/course_data.dart';
import '../core/constants/theme.dart';
import '../core/models/course.dart';
import '../core/providers/progress_provider.dart';

/// A grid of lesson tiles used in the CourseHomeScreen.
class LessonGrid extends ConsumerWidget {
  const LessonGrid({
    super.key,
    required this.courseName,
    required this.lessons,
    required this.startIndex,
    required this.isWide,
  });

  final String courseName;
  final List<LessonData> lessons;
  final int startIndex;
  final bool isWide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crossCount = isWide ? 4 : 3;
    final courseEnum = CourseNameExtension.fromString(courseName);
    final courseInfo =
        courseEnum != null ? getCourseInfo(courseEnum) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Lessons',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.go('/course/$courseName/lessons'),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: AppTheme.spaceSm,
            mainAxisSpacing: AppTheme.spaceSm,
            childAspectRatio: 1.0,
          ),
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final actualIndex = startIndex + index;
            return _LessonTile(
              courseName: courseName,
              lessonIndex: actualIndex,
              displayNumber: actualIndex + 1,
              lessonDuration: lessons[index].duration,
              courseInfo: courseInfo,
            );
          },
        ),
      ],
    );
  }
}

class _LessonTile extends ConsumerWidget {
  const _LessonTile({
    required this.courseName,
    required this.lessonIndex,
    required this.displayNumber,
    required this.lessonDuration,
    this.courseInfo,
  });

  final String courseName;
  final int lessonIndex;
  final int displayNumber;
  final int lessonDuration; // seconds
  final CourseInfo? courseInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(
      lessonProgressProvider((course: courseName, lesson: lessonIndex)),
    );
    final progress = progressAsync.valueOrNull;
    final colors = courseInfo?.uiColors;

    final isFinished = progress?.finished == true;
    final hasProgress = progress?.position != null && !isFinished;

    return GestureDetector(
      onTap: () =>
          context.go('/course/$courseName/listen/$lessonIndex'),
      child: Container(
        decoration: BoxDecoration(
          color: isFinished
              ? (colors?.background ?? AppTheme.primaryColor)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: hasProgress
              ? Border.all(
                  color: colors?.background ?? AppTheme.primaryColor,
                  width: 2,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Progress fill
            if (hasProgress && progress != null)
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: lessonDuration > 0
                      ? (progress.position! / lessonDuration).clamp(0.0, 1.0)
                      : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: (colors?.background ?? AppTheme.primaryColor)
                          .withAlpha(60),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            Center(
              child: isFinished
                  ? Icon(
                      Icons.check,
                      color: colors?.textOnBackground ?? Colors.white,
                      size: 22,
                    )
                  : Text(
                      '$displayNumber',
                      style: TextStyle(
                        color: hasProgress
                            ? (colors?.background ?? AppTheme.primaryColor)
                            : AppTheme.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
