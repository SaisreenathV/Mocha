# Mocha - Project Notes

## Files
- `pubspec.yaml`: Dependencies (riverpod, go_router, soloud, audio_service, audio_session).
- `lib/main.dart`: AudioService.init and ProviderScope initialization.
- `lib/app.dart`: MochaApp routing with ShellRoute.
- `lib/core/theme/mocha_theme.dart`: Material 3 espresso/latte themes.
- `lib/core/shell/adaptive_shell.dart`: Responsive navigation shell.
- `lib/domain/noise_params.dart`: Brown noise parameters and presets model.
- `lib/domain/audio_engine.dart`: AudioEngine interface contract.
- `lib/audio/dsp/brown_noise_synthesizer.dart`: Pure-Dart DSP synthesizer & WAV encoder.
- `lib/audio/soloud_audio_engine.dart`: SoLoud playback engine with isolate rendering.
- `lib/audio/providers.dart`: AudioEngine provider.
- `lib/platform/mocha_audio_handler.dart`: BaseAudioHandler with session interruptions.
- `lib/features/noise/noise_controller.dart`: Playback notifier with permission prompts.
- `lib/features/noise/widgets/depth_dial.dart`: Rotary custom painter dial.
- `lib/features/noise/noise_studio_screen.dart`: Studio UI with sliders, dial, and pulse.
- `lib/features/placeholder_screen.dart`: Generic placeholder for remaining routes.
- `test/brown_noise_test.dart`: DSP validation tests (bounds, mono, seam, slope).
- `tool/render_wav.dart`: CLI tool rendering 30s WAV.

## What Works
- Brown noise DSP synthesis rendered in background isolate with gapless looping.
- Background playback with notification and lock screen controls via audio_service.
- Audio session interruptions: pause on phone calls, duck 50% on notifications.
- Notification permission requested on first play.
- Noise Studio UI with rotary Depth dial, log Cutoff, and instant volume.

## What's Next
- Chunk 6: Offline database with drift for preset persistence and audio library.
- User audio file import with loop controls.
