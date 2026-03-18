import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/course.dart';

/// The playing state exposed to the UI
class PlayerState {
  const PlayerState({
    required this.isPlaying,
    required this.isLoading,
    required this.position,
    required this.duration,
    this.currentLessonIndex,
    this.currentCourse,
    this.errorMessage,
  });

  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final int? currentLessonIndex;
  final CourseName? currentCourse;
  final String? errorMessage;

  static const PlayerState initial = PlayerState(
    isPlaying: false,
    isLoading: false,
    position: Duration.zero,
    duration: Duration.zero,
  );

  PlayerState copyWith({
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    int? currentLessonIndex,
    CourseName? currentCourse,
    String? errorMessage,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      currentLessonIndex: currentLessonIndex ?? this.currentLessonIndex,
      currentCourse: currentCourse ?? this.currentCourse,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  double get progressFraction {
    if (duration.inMilliseconds == 0) return 0;
    return position.inMilliseconds / duration.inMilliseconds;
  }
}

/// Audio handler that integrates with audio_service for background playback
/// on Android and iOS. On web, just_audio handles audio natively in the browser.
class LtAudioHandler extends BaseAudioHandler {
  LtAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _player.durationStream.listen((d) {
      if (d != null) {
        mediaItem.add(mediaItem.value?.copyWith(duration: d));
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        const MediaControl(
          androidIcon: 'drawable/ic_replay_10',
          label: 'Replay 10',
          action: MediaAction.rewind,
        ),
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  // ---------------------------------------------------------------------------
  // MediaItem helpers
  // ---------------------------------------------------------------------------

  Future<void> setLesson({
    required String url,
    required String title,
    required String course,
    required int lessonIndex,
    String? artUri,
    Duration? initialPosition,
  }) async {
    final item = MediaItem(
      id: url,
      title: title,
      album: course,
      extras: {'lessonIndex': lessonIndex, 'course': course},
      artUri: artUri != null ? Uri.parse(artUri) : null,
    );
    mediaItem.add(item);
    await _player.setAudioSource(
      AudioSource.uri(Uri.parse(url)),
      initialPosition: initialPosition,
    );
  }

  // ---------------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------------

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> rewind() async {
    final newPos = _player.position - const Duration(seconds: 10);
    await _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  @override
  Future<void> fastForward() async {
    final newPos = _player.position + const Duration(seconds: 30);
    final dur = _player.duration ?? Duration.zero;
    await _player.seek(newPos > dur ? dur : newPos);
  }

  Future<void> dispose() => _player.dispose();
}
