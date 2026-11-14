# Mocha - Project Notes

## Files
- `pubspec.yaml`: Dependencies and Material 3 design configuration.
- `lib/main.dart`: App entrypoint initializing ProviderScope.
- `lib/app.dart`: MochaApp with GoRouter routes and ShellRoute.
- `lib/core/theme/mocha_theme.dart`: Material 3 espresso/latte themes.
- `lib/core/shell/adaptive_shell.dart`: Responsive shell (bottom bar / sidebar).
- `lib/features/placeholder_screen.dart`: Generic placeholder screen.
- `lib/domain/noise_params.dart`: Brown noise parameters and 6 presets.
- `lib/audio/dsp/brown_noise_synthesizer.dart`: Pure-Dart DSP synthesizer & WAV encoder.
- `test/brown_noise_test.dart`: DSP validation tests (bounds, mono, seam, Goertzel).
- `tool/render_wav.dart`: CLI tool rendering 30s classic brown WAV.

## What Works
- App shell with responsive M3 espresso/latte theming and navigation.
- Pure Dart brown noise generation:
  - Leaky integrator on decorrelated white noise (depth = corner Hz).
  - Biquad low-pass and 180 Hz low-shelf warmth filters.
  - Mid/side stereo width adjustment (exact mono at width 0.0).
  - Equal-power 2-second crossfade for seamless looping.
  - -18 dBFS RMS normalization with tanh soft clipping.
- 16-bit PCM WAV exporter.
- Goertzel filter tests confirming ~ -6 dB/octave slope above corner.

## What's Next
- Chunk 3: Audio engine integration (flutter_soloud) for live brown noise playback.
- Audio service integration for background playback and notification controls.
- Local persistence with drift for custom presets.
