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
  final Map<String, LoopMode> _cache = {};

  LoopController(this._engine, this._db);

  Future<LoopMode> getLoopMode(String itemId, {required bool isSound, bool isBrownNoise = false}) async {
    if (isBrownNoise) return LoopMode.forever;
    if (_cache.containsKey(itemId)) return _cache[itemId]!;

    final data = await _db.getLoopConfig(itemId);
    if (data != null) {
      try {
        final mode = LoopMode.values.byName(data.mode);
        _cache[itemId] = mode;
        return mode;
      } catch (_) {}
    }

    final defaultMode = LoopConfig.defaultModeFor(isSound: isSound, isBrownNoise: isBrownNoise);
    _cache[itemId] = defaultMode;
    return defaultMode;
  }

  Future<void> setLoopMode(String itemId, LoopMode mode) async {
    _cache[itemId] = mode;
    await _engine.setLooping(mode == LoopMode.forever);
    await _db.setLoopConfig(
      ItemLoopConfigsCompanion(
        itemId: Value(itemId),
        mode: Value(mode.name),
      ),
    );
  }

  Future<LoopMode> toggleLoop(String itemId, {required bool isSound, bool isBrownNoise = false}) async {
    if (isBrownNoise) return LoopMode.forever;

    final current = await getLoopMode(itemId, isSound: isSound, isBrownNoise: isBrownNoise);
    final next = current == LoopMode.forever ? LoopMode.off : LoopMode.forever;
    await setLoopMode(itemId, next);
    return next;
  }
}

final loopControllerProvider = Provider<LoopController>((ref) {
  final engine = ref.watch(audioEngineProvider);
  final db = ref.watch(databaseProvider);
  return LoopController(engine, db);
});

final activeLoopModeProvider = StateProvider<LoopMode>((ref) => LoopMode.off);
