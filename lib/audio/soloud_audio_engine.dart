import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../domain/audio_engine.dart';
import '../domain/noise_params.dart';
import 'dsp/brown_noise_synthesizer.dart';

Uint8List _renderNoiseWavIsolate(NoiseParams params) {
  final synth = BrownNoiseSynthesizer();
  final samples = synth.renderStereo(params, seconds: 10.0, sampleRate: 44100);
  return synth.toWav16(samples, sampleRate: 44100);
}

class SoLoudAudioEngine implements AudioEngine {
  // Noise voice
  AudioSource? _noiseSource;
  SoundHandle? _noiseHandle;
  double _noiseVolume = 1.0;
  int _noiseBufferId = 0;

  // File voice
  AudioSource? _fileSource;
  SoundHandle? _fileHandle;
  double _fileVolume = 1.0;
  Duration _fileDuration = Duration.zero;
  Timer? _positionTimer;
  final _positionController = StreamController<Duration>.broadcast();

  @override
  Duration get fileDuration => _fileDuration;

  @override
  Stream<Duration> get filePositionStream => _positionController.stream;

  @override
  Future<void> init() async {
    if (!SoLoud.instance.isInitialized) {
      await SoLoud.instance.init();
    }
  }

  @override
  Future<void> dispose() async {
    _positionTimer?.cancel();
    await stopNoise(fadeDuration: Duration.zero);
    if (_fileHandle != null) {
      SoLoud.instance.stop(_fileHandle!);
      _fileHandle = null;
    }
    if (_fileSource != null) {
      await SoLoud.instance.disposeSource(_fileSource!);
      _fileSource = null;
    }
    await _positionController.close();
    if (SoLoud.instance.isInitialized) {
      await SoLoud.instance.deinit();
    }
  }

  // --- Noise Voice ---

  @override
  Future<void> playNoise(NoiseParams params) async {
    await init();

    final wavBytes = await Isolate.run(() => _renderNoiseWavIsolate(params));
    final soundName = 'brown_noise_${++_noiseBufferId}.wav';
    final newSource = await SoLoud.instance.loadMem(soundName, wavBytes);

    final oldHandle = _noiseHandle;
    final oldSource = _noiseSource;

    if (oldHandle != null) {
      final newHandle = await SoLoud.instance.play(
        newSource,
        looping: true,
        volume: 0.0,
      );
      SoLoud.instance.fadeVolume(newHandle, _noiseVolume, const Duration(milliseconds: 250));
      SoLoud.instance.fadeVolume(oldHandle, 0.0, const Duration(milliseconds: 250));
      SoLoud.instance.scheduleStop(oldHandle, const Duration(milliseconds: 250));

      _noiseHandle = newHandle;
      _noiseSource = newSource;

      if (oldSource != null) {
        Future.delayed(const Duration(milliseconds: 300), () async {
          await SoLoud.instance.disposeSource(oldSource);
        });
      }
    } else {
      _noiseSource = newSource;
      _noiseHandle = await SoLoud.instance.play(
        newSource,
        looping: true,
        volume: _noiseVolume,
      );
    }
  }

  @override
  Future<void> stopNoise({Duration fadeDuration = const Duration(milliseconds: 250)}) async {
    final handle = _noiseHandle;
    final source = _noiseSource;

    _noiseHandle = null;
    _noiseSource = null;

    if (handle != null) {
      if (fadeDuration > Duration.zero) {
        SoLoud.instance.fadeVolume(handle, 0.0, fadeDuration);
        SoLoud.instance.scheduleStop(handle, fadeDuration);
      } else {
        SoLoud.instance.stop(handle);
      }
    }

    if (source != null) {
      final disposeDelay = fadeDuration > Duration.zero
          ? fadeDuration + const Duration(milliseconds: 50)
          : Duration.zero;
      Future.delayed(disposeDelay, () async {
        await SoLoud.instance.disposeSource(source);
      });
    }
  }

  @override
  Future<void> setNoiseVolume(double volume) async {
    _noiseVolume = volume;
    final handle = _noiseHandle;
    if (handle != null) {
      SoLoud.instance.setVolume(handle, volume);
    }
  }

  // --- File Voice ---

  @override
  Future<void> loadAndPlayFile(String path, {bool looping = false}) async {
    await init();

    _positionTimer?.cancel();
    if (_fileHandle != null) {
      SoLoud.instance.stop(_fileHandle!);
      _fileHandle = null;
    }
    if (_fileSource != null) {
      await SoLoud.instance.disposeSource(_fileSource!);
      _fileSource = null;
    }

    final source = await SoLoud.instance.loadFile(path);
    _fileSource = source;
    _fileDuration = SoLoud.instance.getLength(source);

    _fileHandle = await SoLoud.instance.play(
      source,
      volume: _fileVolume,
      looping: looping,
    );

    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final handle = _fileHandle;
      if (handle != null && !_positionController.isClosed) {
        final pos = SoLoud.instance.getPosition(handle);
        _positionController.add(pos);
      }
    });
  }

  @override
  Future<void> pauseFile() async {
    final handle = _fileHandle;
    if (handle != null) {
      SoLoud.instance.setPause(handle, true);
    }
  }

  @override
  Future<void> resumeFile() async {
    final handle = _fileHandle;
    if (handle != null) {
      SoLoud.instance.setPause(handle, false);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    final handle = _fileHandle;
    if (handle != null) {
      SoLoud.instance.seek(handle, position);
      _positionController.add(position);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    final handle = _fileHandle;
    if (handle != null) {
      SoLoud.instance.setRelativePlaySpeed(handle, speed);
    }
  }

  @override
  Future<void> setLooping(bool looping) async {
    final handle = _fileHandle;
    if (handle != null) {
      SoLoud.instance.setLooping(handle, looping);
    }
  }

  @override
  Future<void> setLoopPoint(Duration point) async {
    final handle = _fileHandle;
    if (handle != null) {
      SoLoud.instance.setLoopPoint(handle, point);
    }
  }

  @override
  Future<void> pauseAll() async {
    await stopNoise(fadeDuration: const Duration(milliseconds: 150));
    await pauseFile();
  }
}
