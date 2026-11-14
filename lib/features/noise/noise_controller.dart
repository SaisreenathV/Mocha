import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/providers.dart';
import '../../domain/audio_engine.dart';
import '../../domain/noise_params.dart';

class NoiseState {
  final NoiseParams params;
  final bool isPlaying;
  final String selectedPresetName;

  const NoiseState({
    required this.params,
    this.isPlaying = false,
    this.selectedPresetName = 'Classic Brown',
  });

  NoiseState copyWith({
    NoiseParams? params,
    bool? isPlaying,
    String? selectedPresetName,
  }) {
    return NoiseState(
      params: params ?? this.params,
      isPlaying: isPlaying ?? this.isPlaying,
      selectedPresetName: selectedPresetName ?? this.selectedPresetName,
    );
  }
}

class NoiseController extends StateNotifier<NoiseState> {
  final AudioEngine _engine;

  NoiseController(this._engine)
      : super(const NoiseState(params: NoiseParams.classicBrown));

  Future<void> play() async {
    state = state.copyWith(isPlaying: true);
    await _engine.playNoise(state.params);
  }

  Future<void> stop() async {
    state = state.copyWith(isPlaying: false);
    await _engine.stopNoise();
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await stop();
    } else {
      await play();
    }
  }

  Future<void> selectPreset(String name, NoiseParams params) async {
    state = state.copyWith(params: params, selectedPresetName: name);
    if (state.isPlaying) {
      await _engine.playNoise(params);
    }
  }
}

final noiseControllerProvider =
    StateNotifierProvider<NoiseController, NoiseState>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return NoiseController(engine);
});
