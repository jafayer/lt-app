import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/course_data.dart';
import '../../core/constants/theme.dart';
import '../../core/models/course.dart';
import '../../core/providers/course_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../widgets/lesson_grid.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';

/// Course home screen – cover art, description, lesson grid.
class CourseHomeScreen extends ConsumerWidget {
  const CourseHomeScreen({super.key, required this.courseName});

  final String courseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseNameEnum = CourseNameExtension.fromString(courseName);
    if (courseNameEnum == null) {
      return const Scaffold(body: Center(child: Text('Course not found')));
    }

    final courseInfo = getCourseInfo(courseNameEnum);
    final metadataAsync = ref.watch(courseMetadataProvider(courseName));
    final mostRecent = ref.watch(mostRecentLessonProvider(courseName));

    return Scaffold(
      body: metadataAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, st) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(courseMetadataProvider(courseName)),
        ),
        data: (metadata) {
          if (metadata == null) {
            return const Center(child: Text('No course data available'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide =
                  constraints.maxWidth >= AppTheme.tabletBreakpoint;

              return CustomScrollView(
                slivers: [
                  // Hero header with course colours
                  _CourseHeader(
                    courseInfo: courseInfo,
                    lessonCount: metadata.lessons.length,
                    mostRecentLesson: mostRecent.valueOrNull,
                    isWide: isWide,
                    onPlayFirst: () => context.go(
                      '/course/$courseName/listen/0',
                    ),
                    onPlayRecent: mostRecent.valueOrNull != null
                        ? () => context.go(
                              '/course/$courseName/listen/${mostRecent.valueOrNull}',
                            )
                        : null,
                    onViewAll: () =>
                        context.go('/course/$courseName/lessons'),
                    onManageData: () =>
                        context.go('/course/$courseName/data'),
                  ),
                  // Recent lessons grid (first 6)
                  SliverPadding(
                    padding: EdgeInsets.all(
                        isWide ? AppTheme.spaceLg : AppTheme.spaceMd),
                    sliver: SliverToBoxAdapter(
                      child: LessonGrid(
                        courseName: courseName,
                        lessons: metadata.lessons.take(12).toList(),
                        startIndex: 0,
                        isWide: isWide,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero header widget
// ---------------------------------------------------------------------------

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({
    required this.courseInfo,
    required this.lessonCount,
    required this.mostRecentLesson,
    required this.isWide,
    required this.onPlayFirst,
    required this.onViewAll,
    required this.onManageData,
    this.onPlayRecent,
  });

  final CourseInfo courseInfo;
  final int lessonCount;
  final int? mostRecentLesson;
  final bool isWide;
  final VoidCallback onPlayFirst;
  final VoidCallback? onPlayRecent;
  final VoidCallback onViewAll;
  final VoidCallback onManageData;

  @override
  Widget build(BuildContext context) {
    final colors = courseInfo.uiColors;
    final headerHeight = isWide ? 260.0 : 220.0;

    return SliverToBoxAdapter(
      child: Container(
        height: headerHeight,
        decoration: BoxDecoration(
          color: colors.background,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.background,
              colors.backgroundAccent,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isWide ? AppTheme.spaceLg : AppTheme.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button + title row
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: colors.textOnBackground),
                      onPressed: () => context.go('/'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            courseInfo.fullTitle,
                            style: TextStyle(
                              color: colors.textOnBackground,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$lessonCount lessons · ${courseInfo.courseType == CourseType.complete ? 'Complete' : 'Intro'} course',
                            style: TextStyle(
                              color: colors.textOnBackground.withAlpha(200),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Data management button
                    IconButton(
                      icon: Icon(Icons.download_outlined,
                          color: colors.textOnBackground),
                      tooltip: 'Manage downloads',
                      onPressed: onManageData,
                    ),
                  ],
                ),
                const Spacer(),
                // Action buttons
                Row(
                  children: [
                    _ActionButton(
                      label: onPlayRecent != null
                          ? 'Continue (Lesson ${(mostRecentLesson ?? 0) + 1})'
                          : 'Start Course',
                      icon: Icons.play_circle_filled,
                      color: colors.textOnBackground,
                      backgroundColor: colors.backgroundAccent,
                      onTap: onPlayRecent ?? onPlayFirst,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      label: 'All Lessons',
                      icon: Icons.list,
                      color: colors.textOnBackground,
                      backgroundColor:
                          colors.backgroundAccent.withAlpha(128),
                      onTap: onViewAll,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
