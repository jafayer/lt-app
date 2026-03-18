import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/course_data.dart';
import '../../core/constants/theme.dart';
import '../../core/models/course.dart';
import '../../core/providers/course_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';

/// Shows all lessons for a course in a scrollable list.
class AllLessonsScreen extends ConsumerWidget {
  const AllLessonsScreen({super.key, required this.courseName});

  final String courseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseNameEnum = CourseNameExtension.fromString(courseName);
    if (courseNameEnum == null) {
      return const Scaffold(body: Center(child: Text('Course not found')));
    }

    final courseInfo = getCourseInfo(courseNameEnum);
    final metadataAsync = ref.watch(courseMetadataProvider(courseName));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: courseInfo.uiColors.background,
        foregroundColor: courseInfo.uiColors.textOnBackground,
        title: Text('${courseInfo.shortTitle} – All Lessons'),
        leading: BackButton(
          onPressed: () =>
              context.go('/course/$courseName'),
        ),
      ),
      body: metadataAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, st) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(courseMetadataProvider(courseName)),
        ),
        data: (metadata) {
          if (metadata == null) {
            return const Center(child: Text('No course data'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide =
                  constraints.maxWidth >= AppTheme.tabletBreakpoint;
              final padding = isWide ? AppTheme.space2xl : 0.0;

              return ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: AppTheme.spaceSm,
                ),
                itemCount: metadata.lessons.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final lesson = metadata.lessons[index];
                  return _LessonListTile(
                    courseName: courseName,
                    lesson: lesson,
                    lessonIndex: index,
                    courseInfo: courseInfo,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _LessonListTile extends ConsumerWidget {
  const _LessonListTile({
    required this.courseName,
    required this.lesson,
    required this.lessonIndex,
    required this.courseInfo,
  });

  final String courseName;
  final LessonData lesson;
  final int lessonIndex;
  final CourseInfo courseInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(
      lessonProgressProvider((course: courseName, lesson: lessonIndex)),
    );
    final progress = progressAsync.valueOrNull;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd, vertical: AppTheme.spaceSm),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: progress?.finished == true
              ? courseInfo.uiColors.background
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: progress?.finished == true
              ? Icon(Icons.check, color: courseInfo.uiColors.textOnBackground,
                  size: 20)
              : Text(
                  '${lessonIndex + 1}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
      title: Text(lesson.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(
        formatDuration(lesson.duration),
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing: progress?.position != null && progress?.finished == false
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatDuration(progress!.position!.round()),
                  style: const TextStyle(
                      color: AppTheme.textTertiary, fontSize: 11),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 60,
                  height: 3,
                  child: LinearProgressIndicator(
                    value: progress.position! / lesson.duration,
                    backgroundColor: AppTheme.dividerColor,
                    color: courseInfo.uiColors.background,
                  ),
                ),
              ],
            )
          : null,
      onTap: () =>
          context.go('/course/$courseName/listen/$lessonIndex'),
    );
  }
}
