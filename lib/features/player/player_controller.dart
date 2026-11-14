import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/loop_controller.dart';
import '../../audio/providers.dart';
import '../../data/database.dart';
import '../../domain/audio_engine.dart';
import '../../domain/loop_config.dart';
import '../../platform/mocha_audio_handler.dart';
import '../eq/eq_controller.dart';

class PlayerState {
  final Track? currentTrack;
  final List<Track> queue;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;
  final bool isCrossfading;

  const PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.isCrossfading = false,
  });

  PlayerState copyWith({
    Track? currentTrack,
    List<Track>? queue,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? speed,
    bool? isCrossfading,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
      isCrossfading: isCrossfading ?? this.isCrossfading,
    );
  }
}

class PlayerController extends StateNotifier<PlayerState> {
  final AudioEngine _engine;
  final MochaAudioHandler _audioHandler;
  final Ref _ref;
  StreamSubscription<Duration>? _positionSubscription;

  PlayerController(this._engine, this._audioHandler, this._ref)
      : super(const PlayerState()) {
    _positionSubscription = _engine.filePositionStream.listen(_onPositionUpdate);
  }

  void _onPositionUpdate(Duration pos) {
    if (!mounted) return;
    state = state.copyWith(position: pos);

    // Crossfade check between queue tracks (not while looping)
    if (state.isPlaying &&
        state.duration > Duration.zero &&
        state.queue.isNotEmpty &&
        !state.isCrossfading) {
      final loopMode = _ref.read(activeLoopModeProvider);
      if (loopMode == LoopMode.off) {
        final crossfadeSec = _ref.read(eqControllerProvider).crossfadeSeconds;
        final crossfadeDur = Duration(milliseconds: (crossfadeSec * 1000).round());
        final rem = state.duration - pos;

        if (crossfadeDur > Duration.zero && rem <= crossfadeDur && rem > Duration.zero) {
          _triggerQueueCrossfade(crossfadeDur);
        } else if (rem <= Duration.zero) {
          playNext();
        }
      }
    }
  }

  Future<void> _triggerQueueCrossfade(Duration crossfadeDuration) async {
    if (state.queue.isEmpty || state.isCrossfading) return;
    state = state.copyWith(isCrossfading: true);

    final next = state.queue.first;
    final remainingQueue = state.queue.sublist(1);

    _audioHandler.updateTrack(next);
    await _engine.crossfadeToFile(next.filePath, crossfadeDuration);

    state = state.copyWith(
      currentTrack: next,
      queue: remainingQueue,
      duration: _engine.fileDuration,
      position: Duration.zero,
      isCrossfading: false,
    );
  }

  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    _audioHandler.updateTrack(track);
    await _engine.loadAndPlayFile(track.filePath);
    state = state.copyWith(
      currentTrack: track,
      queue: queue ?? state.queue,
      isPlaying: true,
      duration: _engine.fileDuration,
      position: Duration.zero,
      isCrossfading: false,
    );
  }

  Future<void> playNext({bool useCrossfade = true}) async {
    if (state.queue.isEmpty) return;

    final crossfadeSec = _ref.read(eqControllerProvider).crossfadeSeconds;
    final crossfadeDur = Duration(milliseconds: (crossfadeSec * 1000).round());
    final loopMode = _ref.read(activeLoopModeProvider);

    if (useCrossfade && crossfadeDur > Duration.zero && loopMode == LoopMode.off) {
      await _triggerQueueCrossfade(crossfadeDur);
    } else {
      final next = state.queue.first;
      final remainingQueue = state.queue.sublist(1);
      await playTrack(next, queue: remainingQueue);
    }
  }

  void addToQueue(Track track) {
    state = state.copyWith(queue: [...state.queue, track]);
  }

  void setQueue(List<Track> queue) {
    state = state.copyWith(queue: queue);
  }

  Future<void> pause() async {
    await _engine.pauseFile();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> resume() async {
    await _engine.resumeFile();
    state = state.copyWith(isPlaying: true);
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _engine.seek(position);
    state = state.copyWith(position: position);
  }

  Future<void> setSpeed(double speed) async {
    await _engine.setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

final playerControllerProvider =
    StateNotifierProvider<PlayerController, PlayerState>((ref) {
  final engine = ref.watch(audioEngineProvider);
  final handler = ref.watch(audioHandlerProvider);
  return PlayerController(engine, handler, ref);
});
