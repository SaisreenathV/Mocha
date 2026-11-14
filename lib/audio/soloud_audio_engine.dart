import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
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

  // Single file voice
  AudioSource? _fileSource;
  SoundHandle? _fileHandle;
  double _fileVolume = 1.0;
  Duration _fileDuration = Duration.zero;
  Timer? _positionTimer;
  final _positionController = StreamController<Duration>.broadcast();

  // Layered Sound voices (up to 3 concurrent looping sounds)
  final List<AudioSource?> _layeredSources = [null, null, null];
  final List<SoundHandle?> _layeredHandles = [null, null, null];
  final List<double> _layeredVolumes = [0.8, 0.8, 0.8];

  // Global Equalizer (8 real bands)
  bool _eqEnabled = true;
  final List<double> _eqBands = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  bool _eqInitialized = false;

  @override
  Duration get fileDuration => _fileDuration;

  @override
  Stream<Duration> get filePositionStream => _positionController.stream;

  @override
  Future<void> init() async {
    if (!SoLoud.instance.isInitialized) {
      await SoLoud.instance.init();
    }
    await _initGlobalEq();
  }

  Future<void> _initGlobalEq() async {
    if (_eqInitialized) return;
    try {
      SoLoud.instance.filters.equalizerFilter.activate();
      _eqInitialized = true;
    } catch (_) {}
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
    await stopAllLayeredSounds();
    await _positionController.close();
    if (SoLoud.instance.isInitialized) {
      SoLoud.instance.deinit();
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

  // --- Single File Voice ---

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
  Future<void> crossfadeToFile(String path, Duration duration) async {
    await init();

    if (_fileHandle == null || duration <= Duration.zero) {
      await loadAndPlayFile(path, looping: false);
      return;
    }

    final oldHandle = _fileHandle!;
    final oldSource = _fileSource;

    _positionTimer?.cancel();

    final newSource = await SoLoud.instance.loadFile(path);
    _fileSource = newSource;
    _fileDuration = SoLoud.instance.getLength(newSource);

    final newHandle = await SoLoud.instance.play(
      newSource,
      volume: 0.0,
      looping: false,
    );
    _fileHandle = newHandle;

    SoLoud.instance.fadeVolume(newHandle, _fileVolume, duration);
    SoLoud.instance.fadeVolume(oldHandle, 0.0, duration);
    SoLoud.instance.scheduleStop(oldHandle, duration);

    if (oldSource != null) {
      Future.delayed(duration + const Duration(milliseconds: 100), () async {
        await SoLoud.instance.disposeSource(oldSource);
      });
    }

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

  // --- Layered Sound Voices (up to 3) ---

  @override
  Future<void> playLayeredSound(
    int slot,
    String path, {
    double volume = 0.8,
    bool looping = true,
    Duration? loopPoint,
  }) async {
    if (slot < 0 || slot >= 3) return;
    await init();

    await stopLayeredSound(slot);

    final source = await SoLoud.instance.loadFile(path);
    _layeredSources[slot] = source;
    _layeredVolumes[slot] = volume;

    final handle = await SoLoud.instance.play(
      source,
      volume: volume,
      looping: looping,
    );
    _layeredHandles[slot] = handle;

    if (loopPoint != null) {
      SoLoud.instance.setLoopPoint(handle, loopPoint);
    }
  }

  @override
  Future<void> stopLayeredSound(int slot) async {
    if (slot < 0 || slot >= 3) return;
    final handle = _layeredHandles[slot];
    if (handle != null) {
      SoLoud.instance.stop(handle);
      _layeredHandles[slot] = null;
    }
    final source = _layeredSources[slot];
    if (source != null) {
      await SoLoud.instance.disposeSource(source);
      _layeredSources[slot] = null;
    }
  }

  @override
  Future<void> setLayeredSoundVolume(int slot, double volume) async {
    if (slot < 0 || slot >= 3) return;
    _layeredVolumes[slot] = volume;
    final handle = _layeredHandles[slot];
    if (handle != null) {
      SoLoud.instance.setVolume(handle, volume);
    }
  }

  @override
  Future<void> stopAllLayeredSounds() async {
    for (int i = 0; i < 3; i++) {
      await stopLayeredSound(i);
    }
  }

  // --- Global Equalizer (8 real bands) ---

  @override
  Future<void> setEqBand(int bandIndex, double gainDb) async {
    if (bandIndex < 0 || bandIndex >= 8) return;
    _eqBands[bandIndex] = gainDb;
    if (!_eqEnabled) return;

    await init();
    try {
      final eq = SoLoud.instance.filters.equalizerFilter;
      if (!eq.isActive) eq.activate();
      final linearGain = math.pow(10.0, gainDb / 20.0).toDouble().clamp(0.0, 4.0);
      final bands = [
        eq.band1, eq.band2, eq.band3, eq.band4,
        eq.band5, eq.band6, eq.band7, eq.band8,
      ];
      bands[bandIndex].value = linearGain;
    } catch (_) {}
  }

  @override
  Future<void> applyEqBands(List<double> gainsDb) async {
    for (int i = 0; i < gainsDb.length && i < 8; i++) {
      await setEqBand(i, gainsDb[i]);
    }
  }

  @override
  Future<void> setEqEnabled(bool enabled) async {
    _eqEnabled = enabled;
    await init();
    try {
      final eq = SoLoud.instance.filters.equalizerFilter;
      if (enabled) {
        if (!eq.isActive) eq.activate();
        await applyEqBands(_eqBands);
      } else {
        if (eq.isActive) eq.deactivate();
      }
    } catch (_) {}
  }

  @override
  Future<void> setMasterVolume(double volume) async {
    if (SoLoud.instance.isInitialized) {
      SoLoud.instance.setGlobalVolume(volume.clamp(0.0, 1.0));
    }
  }

  @override
  Future<void> pauseAll() async {
    await stopNoise(fadeDuration: const Duration(milliseconds: 150));
    await pauseFile();
    for (final handle in _layeredHandles) {
      if (handle != null) {
        SoLoud.instance.setPause(handle, true);
      }
    }
  }
}
