import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/providers.dart';
import '../../domain/audio_engine.dart';
import '../../domain/noise_params.dart';

class NoiseState {
  final NoiseParams params;
  final bool isPlaying;
  final bool isUpdating;
  final String selectedPresetName;
  final Map<String, NoiseParams> customPresets;

  const NoiseState({
    required this.params,
    this.isPlaying = false,
    this.isUpdating = false,
    this.selectedPresetName = 'Classic Brown',
    this.customPresets = const {},
  });

  NoiseState copyWith({
    NoiseParams? params,
    bool? isPlaying,
    bool? isUpdating,
    String? selectedPresetName,
    Map<String, NoiseParams>? customPresets,
  }) {
    return NoiseState(
      params: params ?? this.params,
      isPlaying: isPlaying ?? this.isPlaying,
      isUpdating: isUpdating ?? this.isUpdating,
      selectedPresetName: selectedPresetName ?? this.selectedPresetName,
      customPresets: customPresets ?? this.customPresets,
    );
  }
}

class NoiseController extends StateNotifier<NoiseState> {
  final AudioEngine _engine;
  Timer? _debounceTimer;

  NoiseController(this._engine)
      : super(const NoiseState(params: NoiseParams.classicBrown));

  Future<void> play() async {
    state = state.copyWith(isPlaying: true);
    await _engine.playNoise(state.params);
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    state = state.copyWith(isPlaying: false, isUpdating: false);
    await _engine.stopNoise();
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await stop();
    } else {
      await play();
    }
  }

  /// Changes volume instantly without re-rendering DSP audio.
  void setVolume(double volume) {
    state = state.copyWith(params: state.params.copyWith(volume: volume));
    _engine.setNoiseVolume(volume);
  }

  /// Debounces DSP changes (400ms) and sets isUpdating indicator.
  void updateParam(NoiseParams Function(NoiseParams) updater) {
    final updated = updater(state.params);
    state = state.copyWith(
      params: updated,
      selectedPresetName: 'Custom',
    );

    if (state.isPlaying) {
      state = state.copyWith(isUpdating: true);
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
        await _engine.playNoise(state.params);
        if (mounted) {
          state = state.copyWith(isUpdating: false);
        }
      });
    }
  }

  Future<void> selectPreset(String name, NoiseParams params) async {
    _debounceTimer?.cancel();
    state = state.copyWith(
      params: params,
      selectedPresetName: name,
      isUpdating: false,
    );
    if (state.isPlaying) {
      await _engine.playNoise(params);
    }
  }

  void saveCustomPreset(String name) {
    final updated = Map<String, NoiseParams>.from(state.customPresets);
    updated[name] = state.params;
    state = state.copyWith(
      customPresets: updated,
      selectedPresetName: name,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final noiseControllerProvider =
    StateNotifierProvider<NoiseController, NoiseState>((ref) {
  final engine = ref.watch(audioEngineProvider);
  return NoiseController(engine);
});
