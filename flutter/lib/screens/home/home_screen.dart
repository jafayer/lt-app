import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/course_data.dart';
import '../../core/constants/theme.dart';
import '../../core/models/course.dart';
import '../../widgets/course_card.dart';

/// Home screen – shows all available courses in a responsive grid.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Transfer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppTheme.tabletBreakpoint;
          final crossAxisCount = isWide
              ? (constraints.maxWidth / 280).floor().clamp(2, 5)
              : 2;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(isWide ? AppTheme.spaceLg : AppTheme.spaceMd),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Free language courses',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select a course to start learning',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppTheme.spaceLg),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? AppTheme.spaceLg : AppTheme.spaceMd,
                ).copyWith(bottom: AppTheme.spaceLg),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppTheme.spaceMd,
                    mainAxisSpacing: AppTheme.spaceMd,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final course = kAllCourses[index];
                      return CourseCard(
                        course: course,
                        onTap: () =>
                            context.go('/course/${course.name.value}'),
                      );
                    },
                    childCount: kAllCourses.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
