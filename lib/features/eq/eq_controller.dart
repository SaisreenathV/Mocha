import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/providers.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../domain/audio_engine.dart';
import '../../domain/eq_config.dart';

class EqController extends StateNotifier<EqConfig> {
  final AppDatabase _db;
  final AudioEngine _engine;

  EqController(this._db, this._engine) : super(EqConfig.defaultConfig()) {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final settings = await _db.getEqSettings();
    if (settings != null) {
      final bands = EqConfig.parseBands(settings.bandsJson);
      state = state.copyWith(
        enabled: settings.enabled,
        presetName: settings.presetName,
        bands: bands,
        crossfadeSeconds: settings.crossfadeSeconds,
      );
      if (settings.enabled) {
        await _engine.applyEqBands(bands.map((b) => b.gainDb).toList());
      } else {
        await _engine.setEqEnabled(false);
      }
    }
  }

  Future<void> _persist() async {
    await _db.saveEqSettings(EqSettingsTableCompanion(
      id: const Value('global_eq'),
      enabled: Value(state.enabled),
      presetName: Value(state.presetName),
      bandsJson: Value(state.bandsJson),
      crossfadeSeconds: Value(state.crossfadeSeconds),
    ));
  }

  Future<void> toggleEnabled() async {
    final next = !state.enabled;
    state = state.copyWith(enabled: next);
    await _engine.setEqEnabled(next);
    await _persist();
  }

  Future<void> selectPreset(String name) async {
    final gains = EqConfig.presets[name];
    if (gains == null) return;

    final updatedBands = List.generate(
      state.bands.length,
      (i) => state.bands[i].copyWith(gainDb: gains[i]),
    );

    state = state.copyWith(
      presetName: name,
      bands: updatedBands,
    );

    if (state.enabled) {
      await _engine.applyEqBands(gains);
    }
    await _persist();
  }

  Future<void> setBandGain(int index, double gainDb) async {
    if (index < 0 || index >= state.bands.length) return;

    final updatedBands = [...state.bands];
    updatedBands[index] = updatedBands[index].copyWith(gainDb: gainDb);

    state = state.copyWith(
      presetName: 'Custom',
      bands: updatedBands,
    );

    if (state.enabled) {
      await _engine.setEqBand(index, gainDb);
    }
    await _persist();
  }

  Future<void> setCrossfadeSeconds(double seconds) async {
    state = state.copyWith(crossfadeSeconds: seconds);
    await _persist();
  }
}

final eqControllerProvider =
    StateNotifierProvider<EqController, EqConfig>((ref) {
  final db = ref.watch(databaseProvider);
  final engine = ref.watch(audioEngineProvider);
  return EqController(db, engine);
});
