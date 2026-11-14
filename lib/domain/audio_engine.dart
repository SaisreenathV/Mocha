import 'noise_params.dart';

abstract class AudioEngine {
  Future<void> init();
  Future<void> dispose();

  // Noise voice
  Future<void> playNoise(NoiseParams params);
  Future<void> stopNoise({Duration fadeDuration = const Duration(milliseconds: 250)});
  Future<void> setNoiseVolume(double volume);

  // Single file voice (for player / now playing)
  Future<void> loadAndPlayFile(String path, {bool looping = false});
  Future<void> crossfadeToFile(String path, Duration duration);
  Future<void> pauseFile();
  Future<void> resumeFile();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> setLooping(bool looping);
  Future<void> setLoopPoint(Duration point);
  Duration get fileDuration;
  Stream<Duration> get filePositionStream;

  // Layered Sound voices (up to 3 concurrent looping sounds)
  Future<void> playLayeredSound(
    int slot,
    String path, {
    double volume = 0.8,
    bool looping = true,
    Duration? loopPoint,
  });
  Future<void> stopLayeredSound(int slot);
  Future<void> setLayeredSoundVolume(int slot, double volume);
  Future<void> stopAllLayeredSounds();

  // Equalizer (applied on global bus)
  Future<void> setEqEnabled(bool enabled);
  Future<void> setEqBand(int bandIndex, double gainDb);
  Future<void> applyEqBands(List<double> gainsDb);

  // Master volume and pause
  Future<void> setMasterVolume(double volume);
  Future<void> pauseAll();
}
