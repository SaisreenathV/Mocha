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

  @override
  Duration get fileDuration => Duration.zero;

  @override
  Stream<Duration> get filePositionStream => const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<void> init() async {}

  @override
  Future<void> loadAndPlayFile(String path, {bool looping = false}) async {
    lastLoopingValue = looping;
  }

  @override
  Future<void> pauseAll() async {}

  @override
  Future<void> pauseFile() async {}

  @override
  Future<void> playNoise(NoiseParams params) async {}

  @override
  Future<void> resumeFile() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> setLoopPoint(Duration point) async {
    lastLoopPoint = point;
  }

  @override
  Future<void> setLooping(bool looping) async {
    lastLoopingValue = looping;
  }

  @override
  Future<void> setNoiseVolume(double volume) async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Future<void> stopNoise({Duration fadeDuration = const Duration(milliseconds: 250)}) async {}
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
    await db.close();
  });

  group('LoopController', () {
    test('sounds default to forever, songs default to off, brown noise is always forever', () async {
      final songMode = await controller.getLoopMode('song-1', isSound: false);
      final soundMode = await controller.getLoopMode('sound-1', isSound: true);
      final noiseMode = await controller.getLoopMode('brown-noise', isSound: false, isBrownNoise: true);

      expect(songMode, equals(LoopMode.off));
      expect(soundMode, equals(LoopMode.forever));
      expect(noiseMode, equals(LoopMode.forever));
    });

    test('toggling song loop switches to forever, updates engine, and persists to DB', () async {
      expect(fakeEngine.lastLoopingValue, isFalse);

      final next = await controller.toggleLoop('song-1', isSound: false);
      expect(next, equals(LoopMode.forever));
      expect(fakeEngine.lastLoopingValue, isTrue);

      final persisted = await db.getLoopConfig('song-1');
      expect(persisted, isNotNull);
      expect(persisted!.mode, equals('forever'));
    });

    test('toggling sound loop switches to off, updates engine, and persists to DB', () async {
      final next = await controller.toggleLoop('sound-1', isSound: true);
      expect(next, equals(LoopMode.off));
      expect(fakeEngine.lastLoopingValue, isFalse);

      final persisted = await db.getLoopConfig('sound-1');
      expect(persisted, isNotNull);
      expect(persisted!.mode, equals('off'));
    });
  });
}
