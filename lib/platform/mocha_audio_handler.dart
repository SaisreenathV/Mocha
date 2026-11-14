import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/audio_engine.dart';
import '../domain/loop_config.dart';
import '../domain/noise_params.dart';

late final MochaAudioHandler globalAudioHandler;

final audioHandlerProvider = Provider<MochaAudioHandler>((ref) {
  return globalAudioHandler;
});

class MochaAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioEngine _engine;
  NoiseParams _currentNoiseParams = NoiseParams.classicBrown;
  double _userVolume = 1.0;
  bool _isDucked = false;

  Future<void> Function()? _onSkipNext;
  Future<void> Function()? _onSkipPrevious;
  void Function(AudioServiceRepeatMode)? _onRepeatModeChanged;

  MochaAudioHandler(this._engine) {
    _initAudioSession();
    updatePreset('Classic Brown', _currentNoiseParams);
  }

  void setCallbacks({
    Future<void> Function()? onSkipNext,
    Future<void> Function()? onSkipPrevious,
    void Function(AudioServiceRepeatMode)? onRepeatModeChanged,
  }) {
    _onSkipNext = onSkipNext;
    _onSkipPrevious = onSkipPrevious;
    _onRepeatModeChanged = onRepeatModeChanged;
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _isDucked = true;
            _engine.setMasterVolume(_userVolume * 0.5);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _isDucked = false;
            _engine.setMasterVolume(_userVolume);
            break;
          case AudioInterruptionType.pause:
            play();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });

    session.becomingNoisyEventStream.listen((_) {
      pause();
    });
  }

  void updatePreset(String presetName, NoiseParams params) {
    _currentNoiseParams = params;
    mediaItem.add(
      MediaItem(
        id: 'brown_noise',
        album: 'Mocha',
        title: 'Brown Noise - $presetName',
        artist: 'Mocha Offline Audio',
        playable: true,
      ),
    );
  }

  void updateTrack(Track track) {
    mediaItem.add(
      MediaItem(
        id: track.id,
        album: track.album ?? 'Mocha',
        title: track.title,
        artist: track.artist ?? 'Unknown Artist',
        duration: track.durationMs != null ? Duration(milliseconds: track.durationMs!) : null,
        playable: true,
      ),
    );
  }

  void updateLoopStatus(LoopMode mode) {
    AudioServiceRepeatMode repeatMode;
    switch (mode) {
      case LoopMode.off:
        repeatMode = AudioServiceRepeatMode.none;
        break;
      case LoopMode.forever:
      case LoopMode.count:
      case LoopMode.duration:
        repeatMode = AudioServiceRepeatMode.all;
        break;
      case LoopMode.ab:
        repeatMode = AudioServiceRepeatMode.one;
        break;
    }
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  /// Master volume setter — only VolumeController may call this directly.
  void setVolume(double volume) {
    _userVolume = volume;
    _engine.setMasterVolume(_isDucked ? volume * 0.5 : volume);
  }

  void setNoiseVolume(double volume) {
    _engine.setNoiseVolume(volume);
  }

  @override
  Future<void> play() async {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.stop,
          MediaAction.seek,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.setRepeatMode,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: true,
      ),
    );
    await _engine.resumeFile();
  }

  /// Pause handler — MUST NEVER start playback.
  @override
  Future<void> pause() async {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.stop,
          MediaAction.seek,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.setRepeatMode,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: false,
      ),
    );
    await _engine.pauseAll();
  }

  /// Separate PlayPause handler for MPRIS & Tray.
  Future<void> playPause() async {
    if (playbackState.value.playing) {
      await pause();
    } else {
      await play();
    }
  }

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'playPause') {
      await playPause();
    }
    return super.customAction(name, extras);
  }

  @override
  Future<void> skipToNext() async {
    if (_onSkipNext != null) {
      await _onSkipNext!();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_onSkipPrevious != null) {
      await _onSkipPrevious!();
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    _onRepeatModeChanged?.call(repeatMode);
  }

  @override
  Future<void> stop() async {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.play],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await _engine.pauseAll();
  }

  @override
  Future<void> seek(Duration position) async {
    await _engine.seek(position);
    playbackState.add(
      playbackState.value.copyWith(
        updatePosition: position,
      ),
    );
  }
}
