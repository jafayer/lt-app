import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/course_data.dart';
import '../../core/constants/theme.dart';
import '../../core/models/course.dart';
import '../../core/providers/course_provider.dart';
import '../../core/providers/audio_player_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/download_manager.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';

/// Audio player screen.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({
    super.key,
    required this.courseName,
    required this.lessonIndex,
  });

  final String courseName;
  final int lessonIndex;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLesson());
  }

  @override
  void didUpdateWidget(PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseName != widget.courseName ||
        oldWidget.lessonIndex != widget.lessonIndex) {
      _loaded = false;
      _loadLesson();
    }
  }

  Future<void> _loadLesson() async {
    if (_loaded) return;
    _loaded = true;

    final courseNameEnum =
        CourseNameExtension.fromString(widget.courseName);
    if (courseNameEnum == null) return;

    final metadata = await ref
        .read(courseMetadataProvider(widget.courseName).future);
    if (metadata == null) return;

    if (widget.lessonIndex >= metadata.lessons.length) return;
    final lesson = metadata.lessons[widget.lessonIndex];

    final settings = ref.read(settingsProvider).valueOrNull;
    final quality = settings?.streamQuality == 'low'
        ? AudioQuality.low
        : AudioQuality.high;

    final pointer = lesson.pointer(quality);

    // Check local download first (mobile only)
    String url;
    final localPath =
        await DownloadManager.instance.getLocalPath(pointer.object);
    if (localPath != null) {
      url = 'file://$localPath';
    } else {
      final index = await ref.read(courseIndexProvider.future);
      url = '${index.casBaseUrl}/${pointer.object}';
    }

    final progressKey = (course: widget.courseName, lesson: widget.lessonIndex);
    final savedProgress = await ref
        .read(lessonProgressProvider(progressKey).future);

    await ref.read(playerStateProvider.notifier).loadLesson(
          course: courseNameEnum,
          lessonIndex: widget.lessonIndex,
          url: url,
          title: lesson.title,
          startPosition: savedProgress.position,
        );

    await ref.read(playerStateProvider.notifier).play();
  }

  @override
  Widget build(BuildContext context) {
    final courseNameEnum =
        CourseNameExtension.fromString(widget.courseName);
    if (courseNameEnum == null) {
      return const Scaffold(body: Center(child: Text('Course not found')));
    }

    final courseInfo = getCourseInfo(courseNameEnum);
    final metadataAsync = ref.watch(courseMetadataProvider(widget.courseName));
    final playerState = ref.watch(playerStateProvider);

    return Scaffold(
      backgroundColor: courseInfo.uiColors.background,
      body: metadataAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, st) => ErrorView(message: e.toString()),
        data: (metadata) {
          if (metadata == null || widget.lessonIndex >= metadata.lessons.length) {
            return const Center(child: Text('Lesson not found'));
          }

          final lesson = metadata.lessons[widget.lessonIndex];
          final ps = playerState.valueOrNull ?? PlayerState.initial;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide =
                  constraints.maxWidth >= AppTheme.tabletBreakpoint;
              return isWide
                  ? _WidePlayerLayout(
                      courseInfo: courseInfo,
                      lesson: lesson.title,
                      lessonIndex: widget.lessonIndex,
                      totalLessons: metadata.lessons.length,
                      ps: ps,
                      courseName: widget.courseName,
                    )
                  : _NarrowPlayerLayout(
                      courseInfo: courseInfo,
                      lesson: lesson.title,
                      lessonIndex: widget.lessonIndex,
                      totalLessons: metadata.lessons.length,
                      ps: ps,
                      courseName: widget.courseName,
                    );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared player controls widget
// ---------------------------------------------------------------------------

class _PlayerControls extends ConsumerWidget {
  const _PlayerControls({
    required this.ps,
    required this.courseInfo,
    required this.lessonIndex,
    required this.totalLessons,
    required this.courseName,
  });

  final PlayerState ps;
  final CourseInfo courseInfo;
  final int lessonIndex;
  final int totalLessons;
  final String courseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = courseInfo.uiColors.textOnBackground;
    final notifier = ref.read(playerStateProvider.notifier);

    // Scrubber
    final position = ps.position.inSeconds.toDouble();
    final total = ps.duration.inSeconds.toDouble().clamp(1.0, double.infinity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time + scrubber
        Row(
          children: [
            Text(
              _formatTime(ps.position),
              style: TextStyle(color: color.withAlpha(200), fontSize: 12),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: color,
                  inactiveTrackColor: color.withAlpha(60),
                  thumbColor: color,
                  overlayColor: color.withAlpha(30),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: position.clamp(0, total),
                  min: 0,
                  max: total,
                  onChanged: (v) => notifier.seekTo(
                    Duration(seconds: v.round()),
                  ),
                ),
              ),
            ),
            Text(
              _formatTime(ps.duration),
              style: TextStyle(color: color.withAlpha(200), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Playback buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous lesson
            IconButton(
              icon: Icon(Icons.skip_previous, color: color),
              iconSize: 36,
              onPressed: lessonIndex > 0
                  ? () => context.go('/course/$courseName/listen/${lessonIndex - 1}')
                  : null,
            ),
            const SizedBox(width: 8),
            // Replay 10s
            IconButton(
              icon: Icon(Icons.replay_10, color: color),
              iconSize: 36,
              onPressed: () => notifier.rewind10(),
            ),
            const SizedBox(width: 8),
            // Play / Pause
            GestureDetector(
              onTap: () => ps.isPlaying ? notifier.pause() : notifier.play(),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: ps.isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: courseInfo.uiColors.background,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        ps.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: courseInfo.uiColors.background,
                        size: 36,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            // Forward 30s
            IconButton(
              icon: Icon(Icons.forward_30, color: color),
              iconSize: 36,
              onPressed: () => notifier.seekTo(
                ps.position + const Duration(seconds: 30),
              ),
            ),
            const SizedBox(width: 8),
            // Next lesson
            IconButton(
              icon: Icon(Icons.skip_next, color: color),
              iconSize: 36,
              onPressed: lessonIndex < totalLessons - 1
                  ? () => context.go(
                      '/course/$courseName/listen/${lessonIndex + 1}')
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

// ---------------------------------------------------------------------------
// Narrow (mobile) layout
// ---------------------------------------------------------------------------

class _NarrowPlayerLayout extends StatelessWidget {
  const _NarrowPlayerLayout({
    required this.courseInfo,
    required this.lesson,
    required this.lessonIndex,
    required this.totalLessons,
    required this.ps,
    required this.courseName,
  });

  final CourseInfo courseInfo;
  final String lesson;
  final int lessonIndex;
  final int totalLessons;
  final PlayerState ps;
  final String courseName;

  @override
  Widget build(BuildContext context) {
    final color = courseInfo.uiColors.textOnBackground;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: color),
                  onPressed: () => context.go('/course/$courseName'),
                ),
                Expanded(
                  child: Text(
                    courseInfo.shortTitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.list, color: color),
                  onPressed: () =>
                      context.go('/course/$courseName/lessons'),
                ),
              ],
            ),
            const Spacer(),
            // Lesson info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lesson ${lessonIndex + 1} of $totalLessons',
                    style: TextStyle(
                        color: color.withAlpha(180), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            // Controls
            _PlayerControls(
              ps: ps,
              courseInfo: courseInfo,
              lessonIndex: lessonIndex,
              totalLessons: totalLessons,
              courseName: courseName,
            ),
            const SizedBox(height: AppTheme.spaceLg),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wide (tablet/desktop) layout
// ---------------------------------------------------------------------------

class _WidePlayerLayout extends StatelessWidget {
  const _WidePlayerLayout({
    required this.courseInfo,
    required this.lesson,
    required this.lessonIndex,
    required this.totalLessons,
    required this.ps,
    required this.courseName,
  });

  final CourseInfo courseInfo;
  final String lesson;
  final int lessonIndex;
  final int totalLessons;
  final PlayerState ps;
  final String courseName;

  @override
  Widget build(BuildContext context) {
    final color = courseInfo.uiColors.textOnBackground;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: color),
                      onPressed: () => context.go('/course/$courseName'),
                    ),
                    Text(
                      courseInfo.fullTitle,
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: Icon(Icons.list, color: color),
                      label: Text('All lessons',
                          style: TextStyle(color: color)),
                      onPressed: () =>
                          context.go('/course/$courseName/lessons'),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Lesson ${lessonIndex + 1} of $totalLessons',
                  style:
                      TextStyle(color: color.withAlpha(160), fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  lesson,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.space2xl),
                _PlayerControls(
                  ps: ps,
                  courseInfo: courseInfo,
                  lessonIndex: lessonIndex,
                  totalLessons: totalLessons,
                  courseName: courseName,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
