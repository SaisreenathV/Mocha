import 'noise_params.dart';

abstract class AudioEngine {
  Future<void> init();
  Future<void> dispose();
  Future<void> playNoise(NoiseParams params);
  Future<void> stopNoise({Duration fadeDuration = const Duration(milliseconds: 250)});
  Future<void> setNoiseVolume(double volume);
}
