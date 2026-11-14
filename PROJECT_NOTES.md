# Mocha - Project Notes

## Files
- `pubspec.yaml`: Dependencies and Material 3 config.
- `lib/main.dart`: Entrypoint with DB, AudioService, and Riverpod.
- `lib/app.dart`: App routing with ShellRoute.
- `lib/core/theme/mocha_theme.dart`: Material 3 espresso/latte themes.
- `lib/core/shell/adaptive_shell.dart`: Adaptive shell with MiniPlayer & 'L' shortcut.
- `lib/domain/noise_params.dart`: Brown noise parameters model.
- `lib/domain/loop_config.dart`: LoopConfig model (off/forever active; count/duration/ab TODO).
- `lib/domain/audio_engine.dart`: AudioEngine contract with looping voice methods.
- `lib/audio/dsp/brown_noise_synthesizer.dart`: Pure-Dart DSP synthesizer.
- `lib/audio/soloud_audio_engine.dart`: SoLoud dual-voice playback with native looping.
- `lib/audio/loop_controller.dart`: LoopController with sound/song defaults & DB sync.
- `lib/platform/mocha_audio_handler.dart`: AudioService handler with session interruptions.
- `lib/data/database.dart`: Drift database (Tracks & ItemLoopConfigs v2).
- `lib/data/importer.dart`: File/folder importer with Isolate tag parsing.
- `lib/data/providers.dart`: Database, importer, and tracks stream providers.
- `lib/features/noise/noise_studio_screen.dart`: Noise studio controls & depth dial.
- `lib/features/player/player_controller.dart`: Audio file player controller.
- `lib/features/player/mini_player.dart`: MiniPlayer with loop and play controls.
- `lib/features/player/now_playing_screen.dart`: Now playing modal with seek & loop.
- `lib/features/library/library_screen.dart`: Track library UI with "Loop this sound".
- `test/brown_noise_test.dart`: DSP validation tests.
- `test/loop_controller_test.dart`: Loop controller tests with FakeAudioEngine.
- `tool/render_wav.dart`: 30s classic brown WAV generator.

## What Works
- Dual-voice audio engine with native voice looping and master pause.
- Looping logic: sounds default to forever, songs to off, brown noise always forever.
- SQLite schema v2 with ItemLoopConfigs migration remembering loop state per sound.
- Loop controls on MiniPlayer, NowPlayingScreen, and Library rows.
- Desktop 'L' keyboard shortcut ignoring events when an EditableText has focus.
- Full unit tests for loop logic with a fake engine.

## What's Next
- Chunk 9: Multi-sound mixes and volume sliders combining brown noise and tracks.
