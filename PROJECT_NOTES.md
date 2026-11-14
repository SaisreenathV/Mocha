# Mocha - Project Notes

## Files
- `pubspec.yaml`: App dependencies and Material 3 config.
- `lib/main.dart`: Entrypoint with DB, AudioService, and Riverpod.
- `lib/app.dart`: MochaApp routing with ShellRoute.
- `lib/core/theme/mocha_theme.dart`: Material 3 espresso/latte themes.
- `lib/core/shell/adaptive_shell.dart`: Responsive navigation shell.
- `lib/domain/noise_params.dart`: Brown noise parameter model.
- `lib/domain/audio_engine.dart`: AudioEngine contract.
- `lib/audio/dsp/brown_noise_synthesizer.dart`: Pure-Dart DSP synthesizer.
- `lib/audio/soloud_audio_engine.dart`: SoLoud engine with Isolate render.
- `lib/platform/mocha_audio_handler.dart`: AudioService handler & session.
- `lib/data/database.dart`: Drift database with Tracks table.
- `lib/data/importer.dart`: File/folder importer with Isolate metadata reading.
- `lib/data/providers.dart`: Database, importer, and tracks stream providers.
- `lib/features/noise/widgets/depth_dial.dart`: Rotary depth dial widget.
- `lib/features/noise/noise_studio_screen.dart`: Noise studio controls.
- `lib/features/library/library_screen.dart`: Track library UI with search.
- `test/brown_noise_test.dart`: DSP validation tests.
- `tool/render_wav.dart`: 30s classic brown WAV generator.

## What Works
- Responsive M3 shell, theme switching, and navigation rail/bottom bar.
- Brown noise synthesis and background playback with lock-screen notification.
- Audio session interruptions: phone call pause and notification ducking.
- Offline Drift SQLite storage for tracks with reactive search stream.
- File/folder importing with background isolate tag parsing and Android cache handling.
- Song vs. Sound categorization toggle per track.

## What's Next
- Chunk 7: Audio track playback engine, seek bar, and loop controls.
- Custom sound mixes combining brown noise and user audio.
