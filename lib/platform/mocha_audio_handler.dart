import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/audio_engine.dart';
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

  MochaAudioHandler(this._engine) {
    _initAudioSession();
    updatePreset('Classic Brown', _currentNoiseParams);
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

  void setVolume(double volume) {
    _userVolume = volume;
    _engine.setNoiseVolume(_isDucked ? volume * 0.5 : volume);
  }

  @override
  Future<void> play() async {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.pause, MediaControl.stop],
        systemActions: const {MediaAction.play, MediaAction.pause, MediaAction.stop, MediaAction.seek},
        androidCompactActions: const [0],
        processingState: AudioProcessingState.ready,
        playing: true,
      ),
    );
    await _engine.resumeFile();
  }

  @override
  Future<void> pause() async {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [MediaControl.play, MediaControl.stop],
        systemActions: const {MediaAction.play, MediaAction.pause, MediaAction.stop, MediaAction.seek},
        androidCompactActions: const [0],
        processingState: AudioProcessingState.ready,
        playing: false,
      ),
    );
    await _engine.pauseAll();
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
