import 'package:flutter/material.dart';
import '../../core/constants/theme.dart';
import '../../core/models/course.dart';

/// Card widget used in the home screen grid.
class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  final CourseInfo course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = course.uiColors;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.softBackground, colors.backgroundAccent],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.background.withAlpha(80),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course type badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(50),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  course.courseType == CourseType.complete
                      ? 'COMPLETE'
                      : 'INTRO',
                  style: TextStyle(
                    color: colors.textOnBackground.withAlpha(180),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                course.shortTitle,
                style: TextStyle(
                  color: colors.textOnBackground,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${course.fallbackLessonCount} lessons',
                style: TextStyle(
                  color: colors.textOnBackground.withAlpha(180),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
