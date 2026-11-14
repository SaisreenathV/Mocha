# Mocha - Project Notes

## Files
- `pubspec.yaml`: App dependencies and Material 3 config.
- `lib/main.dart`: Entrypoint with DB, AudioService, and Riverpod.
- `lib/app.dart`: App routing with ShellRoute.
- `lib/core/theme/mocha_theme.dart`: Material 3 espresso/latte themes.
- `lib/core/shell/adaptive_shell.dart`: Adaptive shell with MiniPlayer & 'L' shortcut.
- `lib/domain/noise_params.dart`: Brown noise parameters model.
- `lib/domain/loop_config.dart`: LoopConfig model supporting off, forever, count, duration, ab.
- `lib/domain/audio_engine.dart`: AudioEngine contract with looping voice methods.
- `lib/audio/dsp/brown_noise_synthesizer.dart`: Pure-Dart DSP synthesizer.
- `lib/audio/soloud_audio_engine.dart`: SoLoud dual-voice playback with native looping.
- `lib/audio/loop_controller.dart`: LoopController with Count, Duration, and A-B modes.
- `lib/platform/mocha_audio_handler.dart`: AudioService handler with session interruptions.
- `lib/data/database.dart`: Drift database (Tracks & ItemLoopConfigs v2).
- `lib/data/importer.dart`: File/folder importer with Isolate tag parsing.
- `lib/data/providers.dart`: Database, importer, and tracks stream providers.
- `lib/features/noise/noise_studio_screen.dart`: Noise studio controls & depth dial.
- `lib/features/player/player_controller.dart`: Audio file player controller.
- `lib/features/player/mini_player.dart`: MiniPlayer with loop and play controls.
- `lib/features/player/now_playing_screen.dart`: Now playing modal with loop settings.
- `lib/features/player/widgets/loop_config_sheet.dart`: Modal sheet for Count, Timer, and A-B.
- `lib/features/library/library_screen.dart`: Track library UI with "Loop this sound".
- `test/brown_noise_test.dart`: DSP validation tests.
- `test/loop_controller_test.dart`: Loop controller tests for all modes with FakeAudioEngine.
- `tool/render_wav.dart`: 30s classic brown WAV generator.

## What Works
- Dual-voice audio engine with native voice looping and master pause.
- All loop modes: Off, Forever, Count (<2s wrap detection), Duration (30s fadeout & restore), and A-B (near-gapless 15ms seek).
- LoopConfigSheet with RangeSlider markers, Set A / Set B buttons, and count/timer presets.
- Persistent ItemLoopConfigs SQLite storage and desktop 'L' shortcut.

## What's Next
- Chunk 10: Layered audio mixing (combining brown noise generator with looping audio tracks).
