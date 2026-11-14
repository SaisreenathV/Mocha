import 'noise_params.dart';

abstract class AudioEngine {
  Future<void> init();
  Future<void> dispose();

  // Noise voice
  Future<void> playNoise(NoiseParams params);
  Future<void> stopNoise({Duration fadeDuration = const Duration(milliseconds: 250)});
  Future<void> setNoiseVolume(double volume);

  // File voice
  Future<void> loadAndPlayFile(String path, {bool looping = false});
  Future<void> pauseFile();
  Future<void> resumeFile();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> setLooping(bool looping);
  Future<void> setLoopPoint(Duration point);
  Duration get fileDuration;
  Stream<Duration> get filePositionStream;

  // Master pause (pauses all voices)
  Future<void> pauseAll();
}
