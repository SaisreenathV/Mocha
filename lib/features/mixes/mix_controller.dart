import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../domain/mix_model.dart';
import '../../domain/noise_params.dart';
import '../noise/noise_controller.dart';
import '../player/player_controller.dart';

class MixState {
  final SoundscapeMix? currentMix;
  final bool isPlaying;
  final double noiseVolume;
  final double trackVolume;

  const MixState({
    this.currentMix,
    this.isPlaying = false,
    this.noiseVolume = 0.8,
    this.trackVolume = 0.8,
  });

  MixState copyWith({
    SoundscapeMix? currentMix,
    bool? isPlaying,
    double? noiseVolume,
    double? trackVolume,
  }) =>
      MixState(
        currentMix: currentMix ?? this.currentMix,
        isPlaying: isPlaying ?? this.isPlaying,
        noiseVolume: noiseVolume ?? this.noiseVolume,
        trackVolume: trackVolume ?? this.trackVolume,
      );
}

class MixController extends StateNotifier<MixState> {
  final AppDatabase _db;
  final NoiseController _noise;
  final PlayerController _player;

  MixController(this._db, this._noise, this._player)
      : super(const MixState());

  Future<void> playMix(SoundscapeMix mix) async {
    state = state.copyWith(
      currentMix: mix,
      isPlaying: true,
      noiseVolume: mix.noiseVolume,
      trackVolume: mix.trackVolume,
    );

    // Apply noise preset and volume, then play.
    final preset = NoiseParams.presetMap[mix.noisePreset] ??
        NoiseParams.classicBrown;
    await _noise.selectPreset(mix.noisePreset, preset);
    _noise.setVolume(mix.noiseVolume); // sync call
    await _noise.play();

    // Load attached track if present.
    if (mix.trackId != null) {
      final track = await _db.getTrackById(mix.trackId!);
      if (track != null) {
        await _player.playTrack(track);
        // TODO: PlayerController.setVolume — add this method if needed
      }
    }
  }

  Future<void> stopMix() async {
    await _noise.stop();
    await _player.pause();
    state = state.copyWith(isPlaying: false);
  }

  /// Live noise volume — no debounce needed.
  void setNoiseVolume(double v) {
    state = state.copyWith(noiseVolume: v);
    _noise.setVolume(v);
  }

  /// Live track volume — TODO: expose setVolume on PlayerController.
  void setTrackVolume(double v) {
    state = state.copyWith(trackVolume: v);
    // TODO: _player.setVolume(v) once PlayerController exposes it
  }

  Future<void> saveMix(SoundscapeMix mix) async {
    await _db.saveMix(MixesCompanion(
      id: Value(mix.id),
      name: Value(mix.name),
      noisePreset: Value(mix.noisePreset),
      noiseVolume: Value(mix.noiseVolume),
      trackId: Value(mix.trackId),
      trackVolume: Value(mix.trackVolume),
    ));
  }

  Future<void> deleteMix(String id) async {
    if (state.currentMix?.id == id) await stopMix();
    await _db.deleteMix(id);
    if (state.currentMix?.id == id) {
      state = state.copyWith(currentMix: null);
    }
  }
}

final mixControllerProvider =
    StateNotifierProvider<MixController, MixState>((ref) {
  final db = ref.watch(databaseProvider);
  final noise = ref.watch(noiseControllerProvider.notifier);
  final player = ref.watch(playerControllerProvider.notifier);
  return MixController(db, noise, player);
});

final mixesStreamProvider = StreamProvider<List<MixData>>((ref) {
  return ref.watch(databaseProvider).watchAllMixes();
});
