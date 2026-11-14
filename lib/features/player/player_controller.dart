import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/providers.dart';
import '../../data/database.dart';
import '../../domain/audio_engine.dart';
import '../../platform/mocha_audio_handler.dart';

class PlayerState {
  final Track? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final double speed;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
  });

  PlayerState copyWith({
    Track? currentTrack,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    double? speed,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
    );
  }
}

class PlayerController extends StateNotifier<PlayerState> {
  final AudioEngine _engine;
  final MochaAudioHandler _audioHandler;
  StreamSubscription<Duration>? _positionSubscription;

  PlayerController(this._engine, this._audioHandler) : super(const PlayerState()) {
    _positionSubscription = _engine.filePositionStream.listen((pos) {
      if (mounted) {
        state = state.copyWith(position: pos);
      }
    });
  }

  Future<void> playTrack(Track track) async {
    _audioHandler.updateTrack(track);
    await _engine.loadAndPlayFile(track.filePath);
    state = state.copyWith(
      currentTrack: track,
      isPlaying: true,
      duration: _engine.fileDuration,
      position: Duration.zero,
    );
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
  return PlayerController(engine, handler);
});
