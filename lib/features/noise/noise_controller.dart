import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/noise_params.dart';
import '../../platform/mocha_audio_handler.dart';

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
  final MochaAudioHandler _audioHandler;
  Timer? _debounceTimer;
  bool _hasRequestedNotificationPermission = false;
  StreamSubscription? _playbackStateSubscription;

  NoiseController(this._audioHandler)
      : super(const NoiseState(params: NoiseParams.classicBrown)) {
    _playbackStateSubscription = _audioHandler.playbackState.listen((event) {
      if (mounted && state.isPlaying != event.playing) {
        state = state.copyWith(isPlaying: event.playing);
      }
    });
  }

  Future<void> play() async {
    if (Platform.isAndroid && !_hasRequestedNotificationPermission) {
      _hasRequestedNotificationPermission = true;
      await Permission.notification.request();
    }
    _audioHandler.updatePreset(state.selectedPresetName, state.params);
    state = state.copyWith(isPlaying: true);
    await _audioHandler.play();
  }

  Future<void> stop() async {
    _debounceTimer?.cancel();
    state = state.copyWith(isPlaying: false, isUpdating: false);
    await _audioHandler.pause();
  }

  Future<void> togglePlay() async {
    if (state.isPlaying) {
      await stop();
    } else {
      await play();
    }
  }

  void setVolume(double volume) {
    state = state.copyWith(params: state.params.copyWith(volume: volume));
    _audioHandler.setNoiseVolume(volume);
  }

  void updateParam(NoiseParams Function(NoiseParams) updater) {
    final updated = updater(state.params);
    state = state.copyWith(
      params: updated,
      selectedPresetName: 'Custom',
    );
    _audioHandler.updatePreset('Custom', updated);

    if (state.isPlaying) {
      state = state.copyWith(isUpdating: true);
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
        await _audioHandler.play();
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
    _audioHandler.updatePreset(name, params);
    if (state.isPlaying) {
      await _audioHandler.play();
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
    _playbackStateSubscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final noiseControllerProvider =
    StateNotifierProvider<NoiseController, NoiseState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return NoiseController(handler);
});
