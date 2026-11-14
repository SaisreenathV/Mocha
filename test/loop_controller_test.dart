import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocha/audio/loop_controller.dart';
import 'package:mocha/data/database.dart';
import 'package:mocha/domain/audio_engine.dart';
import 'package:mocha/domain/loop_config.dart';
import 'package:mocha/domain/noise_params.dart';

class FakeAudioEngine implements AudioEngine {
  bool lastLoopingValue = false;
  Duration lastLoopPoint = Duration.zero;
  Duration lastSeek = Duration.zero;
  double currentVolume = 1.0;
  bool isFilePaused = false;
  bool isAllPaused = false;

  final _posStreamController = StreamController<Duration>.broadcast();

  void emitPosition(Duration pos) {
    _posStreamController.add(pos);
  }

  @override
  Duration get fileDuration => const Duration(seconds: 1);

  @override
  Stream<Duration> get filePositionStream => _posStreamController.stream;

  @override
  Future<void> dispose() async => _posStreamController.close();

  @override
  Future<void> init() async {}

  @override
  Future<void> loadAndPlayFile(String path, {bool looping = false}) async {
    lastLoopingValue = looping;
  }

  @override
  Future<void> pauseAll() async {
    isAllPaused = true;
  }

  @override
  Future<void> pauseFile() async {
    isFilePaused = true;
  }

  @override
  Future<void> playNoise(NoiseParams params) async {}

  @override
  Future<void> resumeFile() async {
    isFilePaused = false;
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeek = position;
  }

  @override
  Future<void> setLoopPoint(Duration point) async {
    lastLoopPoint = point;
  }

  @override
  Future<void> setLooping(bool looping) async {
    lastLoopingValue = looping;
  }

  @override
  Future<void> setNoiseVolume(double volume) async {
    currentVolume = volume;
  }

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> stopNoise({Duration fadeDuration = const Duration(milliseconds: 250)}) async {}

  Future<void> setFileVolume(double volume) async {}

  @override
  Future<void> setMasterVolume(double volume) async {}

  @override
  Future<void> crossfadeToFile(String path, Duration duration) async {}

  @override
  Future<void> playLayeredSound(int slot, String path, {double volume = 0.8, bool looping = true, Duration? loopPoint}) async {}

  @override
  Future<void> stopLayeredSound(int index) async {}

  @override
  Future<void> stopAllLayeredSounds() async {}

  @override
  Future<void> setLayeredSoundVolume(int index, double volume) async {}

  @override
  Future<void> setEqBand(int bandIndex, double gainDb) async {}

  @override
  Future<void> applyEqBands(List<double> gainsDb) async {}

  @override
  Future<void> setEqEnabled(bool enabled) async {}
}

void main() {
  late FakeAudioEngine fakeEngine;
  late AppDatabase db;
  late LoopController controller;

  setUp(() {
    fakeEngine = FakeAudioEngine();
    db = AppDatabase(NativeDatabase.memory());
    controller = LoopController(fakeEngine, db);
  });

  tearDown(() async {
    controller.dispose();
    await fakeEngine.dispose();
    await db.close();
  });

  group('LoopController Advanced Modes', () {
    test('Count loop: stops after N passes on short audio (<2s)', () async {
      // 500 ms sound with target 2 passes
      controller.setActiveTrack('short-sound', isSound: true, duration: const Duration(milliseconds: 500));
      await controller.applyConfig(const LoopConfig(itemId: 'short-sound', mode: LoopMode.count, count: 2));

      expect(fakeEngine.lastLoopingValue, isTrue);

      // Pass 1: plays from 100ms -> 450ms
      fakeEngine.emitPosition(const Duration(milliseconds: 100));
      fakeEngine.emitPosition(const Duration(milliseconds: 450));
      expect(fakeEngine.isFilePaused, isFalse);

      // Wrap 1 -> Pass 2 starts: jumps back to 50ms
      fakeEngine.emitPosition(const Duration(milliseconds: 50));
      fakeEngine.emitPosition(const Duration(milliseconds: 400));
      expect(fakeEngine.isFilePaused, isFalse);

      // Wrap 2 -> Pass 3 attempted: should stop because target count is 2
      fakeEngine.emitPosition(const Duration(milliseconds: 40));
      expect(fakeEngine.isFilePaused, isTrue);
      expect(fakeEngine.lastLoopingValue, isFalse);
    });

    test('Duration loop: fades out over duration, pauses, and restores original volume', () async {
      controller.setUserVolume(0.7);
      fakeEngine.currentVolume = 0.7;

      // Set duration of 60ms for fast testing
      final config = const LoopConfig(itemId: 'track-1', mode: LoopMode.duration, durationMs: 60);
      await controller.applyConfig(config);

      expect(fakeEngine.lastLoopingValue, isTrue);

      // Wait for countdown + fade to complete
      await Future.delayed(const Duration(milliseconds: 150));

      expect(fakeEngine.isAllPaused, isTrue);
      // Volume restored to user's volume (0.7) and NOT reset to 1.0
      expect(fakeEngine.currentVolume, closeTo(0.7, 0.01));
    });

    test('A-B loop: seeks to A when position >= B (near-gapless)', () async {
      // Set A = 200ms, B = 800ms
      final config = const LoopConfig(itemId: 'track-ab', mode: LoopMode.ab, abStartMs: 200, abEndMs: 800);
      await controller.applyConfig(config);

      expect(fakeEngine.lastLoopingValue, isFalse);

      // Emit position 500ms -> still inside A-B
      fakeEngine.emitPosition(const Duration(milliseconds: 500));
      await Future.delayed(const Duration(milliseconds: 25));
      expect(fakeEngine.lastSeek, equals(Duration.zero));

      // Emit position 850ms -> >= B, should trigger seek to A (200ms)
      fakeEngine.emitPosition(const Duration(milliseconds: 850));
      await Future.delayed(const Duration(milliseconds: 35));
      expect(fakeEngine.lastSeek, equals(const Duration(milliseconds: 200)));
    });
  });
}
