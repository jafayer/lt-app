import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/course/course_home_screen.dart';
import '../../screens/course/all_lessons_screen.dart';
import '../../screens/player/player_screen.dart';
import '../../screens/downloads/data_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../widgets/app_shell.dart';

// Route name constants
class Routes {
  static const home = '/';
  static const course = '/course/:courseName';
  static const allLessons = '/course/:courseName/lessons';
  static const player = '/course/:courseName/listen/:lessonIndex';
  static const data = '/course/:courseName/data';
  static const settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: Routes.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: Routes.home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: Routes.course,
          name: 'course',
          builder: (context, state) {
            final courseName =
                state.pathParameters['courseName']!;
            return CourseHomeScreen(courseName: courseName);
          },
          routes: [
            GoRoute(
              path: 'lessons',
              name: 'allLessons',
              builder: (context, state) {
                final courseName =
                    state.pathParameters['courseName']!;
                return AllLessonsScreen(courseName: courseName);
              },
            ),
            GoRoute(
              path: 'listen/:lessonIndex',
              name: 'player',
              builder: (context, state) {
                final courseName =
                    state.pathParameters['courseName']!;
                final lessonIndex =
                    int.parse(state.pathParameters['lessonIndex']!);
                return PlayerScreen(
                  courseName: courseName,
                  lessonIndex: lessonIndex,
                );
              },
            ),
            GoRoute(
              path: 'data',
              name: 'data',
              builder: (context, state) {
                final courseName =
                    state.pathParameters['courseName']!;
                return DataScreen(courseName: courseName);
              },
            ),
          ],
        ),
        GoRoute(
          path: Routes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
