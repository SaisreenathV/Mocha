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
  AudioSource? _currentSource;
  SoundHandle? _currentHandle;
  double _volume = 1.0;
  int _bufferId = 0;

  @override
  Future<void> init() async {
    if (!SoLoud.instance.isInitialized) {
      await SoLoud.instance.init();
    }
  }

  @override
  Future<void> dispose() async {
    await stopNoise(fadeDuration: Duration.zero);
    if (SoLoud.instance.isInitialized) {
      await SoLoud.instance.deinit();
    }
  }

  @override
  Future<void> playNoise(NoiseParams params) async {
    await init();

    // Render WAV buffer in background isolate
    final wavBytes = await Isolate.run(() => _renderNoiseWavIsolate(params));
    final soundName = 'brown_noise_${++_bufferId}.wav';
    final newSource = await SoLoud.instance.loadMem(soundName, wavBytes);

    final oldHandle = _currentHandle;
    final oldSource = _currentSource;

    if (oldHandle != null) {
      // Crossfade: start new voice silent, fade new in and old out over 250ms
      final newHandle = await SoLoud.instance.play(
        newSource,
        looping: true,
        volume: 0.0,
      );
      SoLoud.instance.fadeVolume(newHandle, _volume, const Duration(milliseconds: 250));
      SoLoud.instance.fadeVolume(oldHandle, 0.0, const Duration(milliseconds: 250));
      SoLoud.instance.scheduleStop(oldHandle, const Duration(milliseconds: 250));

      _currentHandle = newHandle;
      _currentSource = newSource;

      // Dispose old source after crossfade finishes
      if (oldSource != null) {
        Future.delayed(const Duration(milliseconds: 300), () async {
          await SoLoud.instance.disposeSource(oldSource);
        });
      }
    } else {
      // First playback
      _currentSource = newSource;
      _currentHandle = await SoLoud.instance.play(
        newSource,
        looping: true,
        volume: _volume,
      );
    }
  }

  @override
  Future<void> stopNoise({Duration fadeDuration = const Duration(milliseconds: 250)}) async {
    final handle = _currentHandle;
    final source = _currentSource;

    _currentHandle = null;
    _currentSource = null;

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
    _volume = volume;
    final handle = _currentHandle;
    if (handle != null) {
      SoLoud.instance.setVolume(handle, volume);
    }
  }
}
