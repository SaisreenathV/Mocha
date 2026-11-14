import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/providers.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../domain/audio_engine.dart';
import '../../domain/noise_params.dart';
import '../../domain/saved_mix.dart';
import '../noise/noise_controller.dart';

class MixState {
  final SavedMix? activeSavedMix;
  final bool isPlaying;
  final NoiseParams currentNoiseParams;
  final double noiseVolume;
  final List<LayeredSoundConfig> layeredSounds;

  const MixState({
    this.activeSavedMix,
    this.isPlaying = false,
    this.currentNoiseParams = NoiseParams.classicBrown,
    this.noiseVolume = 0.8,
    this.layeredSounds = const [],
  });

  MixState copyWith({
    SavedMix? activeSavedMix,
    bool? isPlaying,
    NoiseParams? currentNoiseParams,
    double? noiseVolume,
    List<LayeredSoundConfig>? layeredSounds,
    bool clearActiveMix = false,
  }) {
    return MixState(
      activeSavedMix:
          clearActiveMix ? null : (activeSavedMix ?? this.activeSavedMix),
      isPlaying: isPlaying ?? this.isPlaying,
      currentNoiseParams: currentNoiseParams ?? this.currentNoiseParams,
      noiseVolume: noiseVolume ?? this.noiseVolume,
      layeredSounds: layeredSounds ?? this.layeredSounds,
    );
  }
}

class MixController extends StateNotifier<MixState> {
  final AppDatabase _db;
  final NoiseController _noise;
  final AudioEngine _engine;

  MixController(this._db, this._noise, this._engine) : super(const MixState());

  void setNoiseParams(NoiseParams params) {
    state = state.copyWith(currentNoiseParams: params);
    if (state.isPlaying) {
      _engine.playNoise(params);
    }
  }

  void setNoiseVolume(double volume) {
    state = state.copyWith(noiseVolume: volume);
    _engine.setNoiseVolume(volume);
  }

  Future<void> addSound(Track track, {double volume = 0.8, String loopMode = 'forever'}) async {
    if (state.layeredSounds.length >= 3) return;

    final config = LayeredSoundConfig(
      trackId: track.id,
      filePath: track.filePath,
      title: track.title,
      volume: volume,
      loopMode: loopMode,
    );
    final updated = [...state.layeredSounds, config];
    final slot = updated.length - 1;
    state = state.copyWith(layeredSounds: updated);

    if (state.isPlaying) {
      await _engine.playLayeredSound(
        slot,
        config.filePath,
        volume: config.volume,
        looping: config.loopMode != 'off',
      );
    }
  }

  Future<void> removeSound(int slot) async {
    if (slot < 0 || slot >= state.layeredSounds.length) return;
    await _engine.stopLayeredSound(slot);

    final updated = [...state.layeredSounds]..removeAt(slot);
    state = state.copyWith(layeredSounds: updated);

    // Replay remaining sounds to adjust slots if active
    if (state.isPlaying) {
      await _engine.stopAllLayeredSounds();
      for (int i = 0; i < updated.length; i++) {
        final s = updated[i];
        await _engine.playLayeredSound(
          i,
          s.filePath,
          volume: s.volume,
          looping: s.loopMode != 'off',
        );
      }
    }
  }

  Future<void> setLayerVolume(int slot, double volume) async {
    if (slot < 0 || slot >= state.layeredSounds.length) return;
    final updated = [...state.layeredSounds];
    final current = updated[slot];
    updated[slot] = LayeredSoundConfig(
      trackId: current.trackId,
      filePath: current.filePath,
      title: current.title,
      volume: volume,
      loopMode: current.loopMode,
      count: current.count,
      durationMs: current.durationMs,
      abStartMs: current.abStartMs,
      abEndMs: current.abEndMs,
    );
    state = state.copyWith(layeredSounds: updated);
    await _engine.setLayeredSoundVolume(slot, volume);
  }

  /// Restore saved mix in one tap.
  Future<void> restoreMix(SavedMix mix) async {
    final noiseParams = SavedMixModel.parseNoiseParams(mix.noiseParamsJson);
    final sounds = SavedMixModel.parseSounds(mix.soundsJson);

    state = state.copyWith(
      activeSavedMix: mix,
      isPlaying: true,
      currentNoiseParams: noiseParams,
      noiseVolume: mix.noiseVolume,
      layeredSounds: sounds,
    );

    // Restore noise
    await _engine.playNoise(noiseParams);
    await _engine.setNoiseVolume(mix.noiseVolume);

    // Restore up to 3 layered sounds with volumes and loop states
    await _engine.stopAllLayeredSounds();
    for (int i = 0; i < sounds.length && i < 3; i++) {
      final s = sounds[i];
      Duration? loopPoint;
      if (s.abStartMs != null) {
        loopPoint = Duration(milliseconds: s.abStartMs!);
      }
      await _engine.playLayeredSound(
        i,
        s.filePath,
        volume: s.volume,
        looping: s.loopMode != 'off',
        loopPoint: loopPoint,
      );
    }
  }

  Future<void> stopMix() async {
    await _engine.stopNoise();
    await _engine.stopAllLayeredSounds();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> playMix() async {
    state = state.copyWith(isPlaying: true);
    await _engine.playNoise(state.currentNoiseParams);
    await _engine.setNoiseVolume(state.noiseVolume);

    for (int i = 0; i < state.layeredSounds.length && i < 3; i++) {
      final s = state.layeredSounds[i];
      Duration? loopPoint;
      if (s.abStartMs != null) {
        loopPoint = Duration(milliseconds: s.abStartMs!);
      }
      await _engine.playLayeredSound(
        i,
        s.filePath,
        volume: s.volume,
        looping: s.loopMode != 'off',
        loopPoint: loopPoint,
      );
    }
  }

  Future<void> saveCurrentMix(String name) async {
    final model = SavedMixModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      noiseParams: state.currentNoiseParams,
      noiseVolume: state.noiseVolume,
      sounds: state.layeredSounds,
    );

    await _db.saveSavedMix(SavedMixesCompanion(
      id: Value(model.id),
      name: Value(model.name),
      noiseParamsJson: Value(model.noiseParamsJson),
      noiseVolume: Value(model.noiseVolume),
      soundsJson: Value(model.soundsJson),
    ));
  }

  Future<void> deleteSavedMix(String id) async {
    if (state.activeSavedMix?.id == id) {
      await stopMix();
      state = state.copyWith(clearActiveMix: true);
    }
    await _db.deleteSavedMix(id);
  }
}

final mixControllerProvider =
    StateNotifierProvider<MixController, MixState>((ref) {
  final db = ref.watch(databaseProvider);
  final noise = ref.watch(noiseControllerProvider.notifier);
  final engine = ref.watch(audioEngineProvider);
  return MixController(db, noise, engine);
});

final savedMixesStreamProvider = StreamProvider<List<SavedMix>>((ref) {
  return ref.watch(databaseProvider).watchAllSavedMixes();
});
