# Mocha - Project Notes

## Files
- `pubspec.yaml`: Dependencies (flutter_riverpod, go_router, flutter_soloud).
- `lib/main.dart`: Entrypoint initializing ProviderScope.
- `lib/app.dart`: MochaApp with GoRouter routes and ShellRoute.
- `lib/core/theme/mocha_theme.dart`: Material 3 espresso and latte themes.
- `lib/core/shell/adaptive_shell.dart`: Responsive navigation shell.
- `lib/domain/noise_params.dart`: Noise parameters, copyWith, and 6 presets.
- `lib/domain/audio_engine.dart`: AudioEngine interface contract.
- `lib/audio/dsp/brown_noise_synthesizer.dart`: Pure-Dart DSP synthesizer & WAV encoder.
- `lib/audio/soloud_audio_engine.dart`: SoLoud playback with Isolate and crossfade.
- `lib/audio/providers.dart`: AudioEngine Riverpod provider.
- `lib/features/noise/noise_controller.dart`: Debounced notifier (400ms) with presets.
- `lib/features/noise/widgets/depth_dial.dart`: Rotary custom painter dial for corner Hz.
- `lib/features/noise/noise_studio_screen.dart`: Studio UI with sliders, dial, and pulse.
- `lib/features/placeholder_screen.dart`: Generic placeholder for other routes.
- `test/brown_noise_test.dart`: DSP validation tests (bounds, mono, seam, slope).
- `tool/render_wav.dart`: CLI tool rendering 30s WAV.

## What Works
- Noise Studio UI with rotary Depth dial and log Cutoff slider (80-8000 Hz).
- Warmth (-6 to +6 dB), Stereo Width (0 to 100%), and instant Volume slider.
- 400ms debounced DSP re-rendering with "Updating..." indicator.
- Pulsing circle animation on Play button while playing.
- In-memory custom preset creation and selection alongside 6 built-ins.

## What's Next
- Chunk 5: Background audio service integration (`audio_service`).
- Local persistence with drift for custom presets.
- Audio file player integration and loop controls.
