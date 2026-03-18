import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/course.dart';
import '../services/audio_handler.dart';
import 'progress_provider.dart';

// ---------------------------------------------------------------------------
// Audio handler singleton
// ---------------------------------------------------------------------------

final audioHandlerProvider =
    Provider<LtAudioHandler>((ref) => throw UnimplementedError(
          'audioHandlerProvider must be overridden in main with the real handler',
        ));

// ---------------------------------------------------------------------------
// Player state provider
// ---------------------------------------------------------------------------

final playerStateProvider =
    AsyncNotifierProvider<PlayerStateNotifier, PlayerState>(
  PlayerStateNotifier.new,
);

class PlayerStateNotifier extends AsyncNotifier<PlayerState> {
  StreamSubscription<PlaybackEvent>? _eventSub;
  StreamSubscription<Duration>? _positionSub;
  Timer? _progressSaveTimer;

  // 5 seconds before end = lesson "finished"
  static const _finishThreshold = Duration(seconds: 5);
  // Save progress every 3 seconds
  static const _saveInterval = Duration(seconds: 3);

  @override
  Future<PlayerState> build() async {
    final handler = ref.watch(audioHandlerProvider);
    final player = handler.player;

    _eventSub?.cancel();
    _positionSub?.cancel();
    _progressSaveTimer?.cancel();

    _eventSub = player.playbackEventStream.listen((_) {
      _updateFromPlayer(player);
    });

    _positionSub = player.positionStream.listen((_) {
      _updateFromPlayer(player);
    });

    // Periodic progress save
    _progressSaveTimer = Timer.periodic(_saveInterval, (_) async {
      final ps = state.valueOrNull;
      if (ps == null || ps.currentCourse == null) return;
      if (!player.playing) return;
      _saveCurrentProgress(ps);
    });

    ref.onDispose(() {
      _eventSub?.cancel();
      _positionSub?.cancel();
      _progressSaveTimer?.cancel();
    });

    return PlayerState.initial;
  }

  void _updateFromPlayer(AudioPlayer player) {
    final current = state.valueOrNull ?? PlayerState.initial;
    final newState = current.copyWith(
      isPlaying: player.playing,
      isLoading: player.processingState == ProcessingState.loading ||
          player.processingState == ProcessingState.buffering,
      position: player.position,
      duration: player.duration ?? Duration.zero,
    );
    state = AsyncValue.data(newState);

    // Auto-detect lesson finish
    final dur = player.duration;
    if (dur != null && dur.inMilliseconds > 0) {
      final remaining = dur - player.position;
      if (remaining <= _finishThreshold &&
          current.currentLessonIndex != null &&
          current.currentCourse != null) {
        _markLessonFinished(current);
      }
    }
  }

  void _saveCurrentProgress(PlayerState ps) {
    if (ps.currentLessonIndex == null || ps.currentCourse == null) return;
    ref
        .read(lessonProgressProvider(
          (course: ps.currentCourse!.value, lesson: ps.currentLessonIndex!),
        ).notifier)
        .saveProgress(ps.position.inSeconds.toDouble());
  }

  void _markLessonFinished(PlayerState ps) {
    if (ps.currentLessonIndex == null || ps.currentCourse == null) return;
    ref
        .read(lessonProgressProvider(
          (course: ps.currentCourse!.value, lesson: ps.currentLessonIndex!),
        ).notifier)
        .markFinished();
  }

  // ---------------------------------------------------------------------------
  // Load a lesson into the player
  // ---------------------------------------------------------------------------

  Future<void> loadLesson({
    required CourseName course,
    required int lessonIndex,
    required String url,
    required String title,
    double? startPosition,
  }) async {
    final handler = ref.read(audioHandlerProvider);
    state = AsyncValue.data(
      (state.valueOrNull ?? PlayerState.initial).copyWith(
        isLoading: true,
        currentCourse: course,
        currentLessonIndex: lessonIndex,
      ),
    );

    await handler.setLesson(
      url: url,
      title: title,
      course: course.value,
      lessonIndex: lessonIndex,
      initialPosition: startPosition != null
          ? Duration(milliseconds: (startPosition * 1000).round())
          : null,
    );

    // Update most-recent tracking
    await ref
        .read(mostRecentCourseProvider.notifier)
        .save(course);
    await ref
        .read(mostRecentLessonProvider(course.value).notifier)
        .save(lessonIndex);
  }

  // ---------------------------------------------------------------------------
  // Playback controls
  // ---------------------------------------------------------------------------

  Future<void> play() async {
    final handler = ref.read(audioHandlerProvider);
    await handler.play();
  }

  Future<void> pause() async {
    final handler = ref.read(audioHandlerProvider);
    await handler.pause();
  }

  Future<void> seekTo(Duration position) async {
    final handler = ref.read(audioHandlerProvider);
    await handler.seek(position);
  }

  Future<void> rewind10() async {
    final handler = ref.read(audioHandlerProvider);
    await handler.rewind();
  }
}
