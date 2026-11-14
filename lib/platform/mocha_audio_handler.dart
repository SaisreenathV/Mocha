import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/audio_engine.dart';
import '../domain/noise_params.dart';

late final MochaAudioHandler globalAudioHandler;

final audioHandlerProvider = Provider<MochaAudioHandler>((ref) {
  return globalAudioHandler;
});

class MochaAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioEngine _engine;
  NoiseParams _currentParams = NoiseParams.classicBrown;
  double _userVolume = 1.0;
  bool _isDucked = false;

  MochaAudioHandler(this._engine) {
    _initAudioSession();
    updatePreset('Classic Brown', _currentParams);
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _isDucked = true;
            _engine.setNoiseVolume(_userVolume * 0.5);
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
            _engine.setNoiseVolume(_userVolume);
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
    _currentParams = params;
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

  void setVolume(double volume) {
    _userVolume = volume;
    _engine.setNoiseVolume(_isDucked ? volume * 0.5 : volume);
  }

  @override
  Future<void> play() async {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.pause, MediaControl.stop],
        systemActions: const {MediaAction.play, MediaAction.pause, MediaAction.stop},
        androidCompactActions: const [0],
        processingState: AudioProcessingState.ready,
        playing: true,
      ),
    );
    await _engine.playNoise(_currentParams);
  }

  @override
  Future<void> pause() async {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.play, MediaControl.stop],
        systemActions: const {MediaAction.play, MediaAction.pause, MediaAction.stop},
        androidCompactActions: const [0],
        processingState: AudioProcessingState.ready,
        playing: false,
      ),
    );
    await _engine.stopNoise();
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
    await _engine.stopNoise();
  }
}
