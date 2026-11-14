import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../data/providers.dart';
import '../domain/audio_engine.dart';
import '../domain/loop_config.dart';
import 'providers.dart';

class LoopController {
  final AudioEngine _engine;
  final AppDatabase _db;
  final Map<String, LoopConfig> _cache = {};

  // Active loop state
  LoopConfig? _activeConfig;
  Duration _trackDuration = Duration.zero;
  Duration? _lastPosition;
  int _currentPass = 1;
  double _userVolume = 1.0;

  StreamSubscription<Duration>? _positionSubscription;
  Timer? _abPollTimer;
  Timer? _durationTimer;

  LoopController(this._engine, this._db) {
    _positionSubscription = _engine.filePositionStream.listen(_onPositionUpdate);
  }

  void setUserVolume(double volume) {
    _userVolume = volume;
  }

  void setActiveTrack(String itemId, {required bool isSound, required Duration duration}) async {
    _trackDuration = duration;
    _lastPosition = null;
    _currentPass = 1;
    _cancelTimers();

    final config = await getLoopConfig(itemId, isSound: isSound);
    await applyConfig(config);
  }

  Future<LoopConfig> getLoopConfig(String itemId, {required bool isSound, bool isBrownNoise = false}) async {
    if (isBrownNoise) {
      return LoopConfig(itemId: itemId, mode: LoopMode.forever);
    }
    if (_cache.containsKey(itemId)) {
      return _cache[itemId]!;
    }

    final data = await _db.getLoopConfig(itemId);
    if (data != null) {
      try {
        final mode = LoopMode.values.byName(data.mode);
        final config = LoopConfig(
          itemId: itemId,
          mode: mode,
          count: data.count,
          durationMs: data.durationMs,
          abStartMs: data.abStartMs,
          abEndMs: data.abEndMs,
        );
        _cache[itemId] = config;
        return config;
      } catch (_) {}
    }

    final defaultMode = LoopConfig.defaultModeFor(isSound: isSound, isBrownNoise: isBrownNoise);
    final config = LoopConfig(itemId: itemId, mode: defaultMode);
    _cache[itemId] = config;
    return config;
  }

  Future<void> applyConfig(LoopConfig config) async {
    _activeConfig = config;
    _cache[config.itemId] = config;
    _cancelTimers();
    _currentPass = 1;

    // Persist to Drift
    await _db.setLoopConfig(
      ItemLoopConfigsCompanion(
        itemId: Value(config.itemId),
        mode: Value(config.mode.name),
        count: Value(config.count),
        durationMs: Value(config.durationMs),
        abStartMs: Value(config.abStartMs),
        abEndMs: Value(config.abEndMs),
      ),
    );

    switch (config.mode) {
      case LoopMode.off:
        await _engine.setLooping(false);
        break;

      case LoopMode.forever:
        await _engine.setLooping(true);
        await _engine.setLoopPoint(Duration.zero);
        break;

      case LoopMode.count:
        // Use native looping while counting passes
        await _engine.setLooping(true);
        await _engine.setLoopPoint(Duration.zero);
        break;

      case LoopMode.duration:
        await _engine.setLooping(true);
        if (config.durationMs != null && config.durationMs! > 0) {
          _startDurationCountdown(Duration(milliseconds: config.durationMs!));
        }
        break;

      case LoopMode.ab:
        // Native looping disabled so high-frequency poll can seek to A
        await _engine.setLooping(false);
        _startAbPolling(config);
        break;
    }
  }

  Future<LoopMode> toggleLoop(String itemId, {required bool isSound, bool isBrownNoise = false}) async {
    if (isBrownNoise) return LoopMode.forever;

    final current = await getLoopConfig(itemId, isSound: isSound, isBrownNoise: isBrownNoise);
    final nextMode = current.mode == LoopMode.forever ? LoopMode.off : LoopMode.forever;
    final updated = current.copyWith(mode: nextMode);
    await applyConfig(updated);
    return nextMode;
  }

  void _onPositionUpdate(Duration pos) {
    if (_activeConfig == null) return;

    if (_activeConfig!.mode == LoopMode.count) {
      final target = _activeConfig!.count ?? 1;
      // Detect wrap: current position jumped backwards or reached duration edge
      // Handles sounds shorter than 2 seconds by checking wrap jump relative to duration
      final last = _lastPosition;
      final threshold = _trackDuration > const Duration(seconds: 2)
          ? const Duration(milliseconds: 300)
          : Duration(milliseconds: _trackDuration.inMilliseconds ~/ 3);

      final isWrap = last != null && pos < last && (last - pos >= threshold);

      if (isWrap) {
        _currentPass++;
        if (_currentPass > target) {
          _engine.setLooping(false);
          _engine.pauseFile();
        }
      }
    }

    _lastPosition = pos;
  }

  /// A-B Looping: polls position every 15 ms and seeks to A when position >= B.
  /// NOTE: This implementation is near-gapless, NOT sample-accurate.
  void _startAbPolling(LoopConfig config) {
    if (config.abStartMs == null || config.abEndMs == null) return;
    final start = Duration(milliseconds: config.abStartMs!);
    final end = Duration(milliseconds: config.abEndMs!);
    if (end <= start) return;

    _abPollTimer?.cancel();
    _abPollTimer = Timer.periodic(const Duration(milliseconds: 15), (_) async {
      final pos = _lastPosition;
      if (pos != null && pos >= end) {
        await _engine.seek(start);
      }
    });
  }

  /// Duration countdown: when time is up, fade out over 30s then pause,
  /// and restore the user's own volume (do not reset to 100%).
  void _startDurationCountdown(Duration totalDuration) {
    _durationTimer?.cancel();
    final fadeDuration = totalDuration < const Duration(seconds: 30)
        ? Duration(milliseconds: totalDuration.inMilliseconds ~/ 2)
        : const Duration(seconds: 30);
    final playDuration = totalDuration - fadeDuration;

    _durationTimer = Timer(playDuration, () async {
      const steps = 30;
      final stepDuration = Duration(milliseconds: fadeDuration.inMilliseconds ~/ steps);
      for (int i = 0; i < steps; i++) {
        final factor = 1.0 - (i / steps);
        await _engine.setNoiseVolume(_userVolume * factor);
        await Future.delayed(stepDuration);
      }
      await _engine.pauseAll();
      // Restore user's own volume without resetting to 1.0
      await _engine.setNoiseVolume(_userVolume);
    });
  }

  void _cancelTimers() {
    _abPollTimer?.cancel();
    _durationTimer?.cancel();
    _abPollTimer = null;
    _durationTimer = null;
  }

  void dispose() {
    _positionSubscription?.cancel();
    _cancelTimers();
  }
}

final loopControllerProvider = Provider<LoopController>((ref) {
  final engine = ref.watch(audioEngineProvider);
  final db = ref.watch(databaseProvider);
  final controller = LoopController(engine, db);
  ref.onDispose(controller.dispose);
  return controller;
});

final activeLoopModeProvider = StateProvider<LoopMode>((ref) => LoopMode.off);
final activeLoopConfigProvider = StateProvider<LoopConfig?>((ref) => null);
