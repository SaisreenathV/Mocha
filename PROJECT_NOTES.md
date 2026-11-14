# Mocha - Project Notes

## Files
- `pubspec.yaml`: Dependencies (flutter_riverpod, go_router, flutter_soloud).
- `lib/main.dart`: Entrypoint initializing ProviderScope.
- `lib/app.dart`: MochaApp with GoRouter routes and ShellRoute.
- `lib/core/theme/mocha_theme.dart`: Material 3 espresso and latte themes.
- `lib/core/shell/adaptive_shell.dart`: Responsive navigation shell.
- `lib/domain/noise_params.dart`: Brown noise parameter model and 6 presets.
- `lib/domain/audio_engine.dart`: AudioEngine interface contract.
- `lib/audio/dsp/brown_noise_synthesizer.dart`: Pure-Dart DSP engine & WAV encoder.
- `lib/audio/soloud_audio_engine.dart`: SoLoud playback with Isolate and crossfade.
- `lib/audio/providers.dart`: AudioEngine Riverpod provider.
- `lib/features/noise/noise_controller.dart`: StateNotifier for noise playback.
- `lib/features/noise/noise_screen.dart`: UI with preset chips and Play/Stop button.
- `lib/features/placeholder_screen.dart`: Generic placeholder for other routes.
- `test/brown_noise_test.dart`: DSP validation tests (bounds, mono, seam, slope).
- `tool/render_wav.dart`: CLI tool rendering 30s WAV.

## What Works
- Responsive shell with espresso/latte themes and adaptive navigation.
- Pure Dart brown noise synthesizer with seamless looping crossfade.
- In-memory audio playback via flutter_soloud with 250ms crossfading.
- Noise screen with 6 preset chips and interactive Play/Stop control.

## What's Next
- Chunk 4: Background playback lifecycle integration (audio_service).
- Local storage schema with drift for custom presets.
- User audio file import and loop controls.
