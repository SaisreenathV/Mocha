# Mocha - Project Notes

## Files
- `pubspec.yaml`: App dependencies and Material 3 config.
- `lib/main.dart`: Entrypoint with DB, AudioService, and Riverpod.
- `lib/app.dart`: App routing with ShellRoute (Mixes wired).
- `lib/core/theme/mocha_theme.dart`: Material 3 espresso/latte themes.
- `lib/core/shell/adaptive_shell.dart`: Adaptive shell with MiniPlayer & 'L' shortcut.
- `lib/domain/noise_params.dart`: Brown noise parameters model + presetMap.
- `lib/domain/loop_config.dart`: LoopConfig model (off, forever, count, duration, ab).
- `lib/domain/mix_model.dart`: SoundscapeMix domain model.
- `lib/domain/audio_engine.dart`: AudioEngine contract with looping voice methods.
- `lib/audio/dsp/brown_noise_synthesizer.dart`: Pure-Dart DSP synthesizer.
- `lib/audio/soloud_audio_engine.dart`: SoLoud dual-voice playback with native looping.
- `lib/audio/loop_controller.dart`: LoopController with Count, Duration, and A-B modes.
- `lib/platform/mocha_audio_handler.dart`: AudioService handler with session interruptions.
- `lib/data/database.dart`: Drift database (Tracks, ItemLoopConfigs, Mixes v3).
- `lib/data/importer.dart`: File/folder importer with Isolate tag parsing.
- `lib/data/providers.dart`: Database, importer, and tracks stream providers.
- `lib/features/noise/noise_studio_screen.dart`: Noise studio controls & depth dial.
- `lib/features/player/player_controller.dart`: Audio file player controller.
- `lib/features/player/mini_player.dart`: MiniPlayer with loop and play controls.
- `lib/features/player/now_playing_screen.dart`: Now playing modal with loop settings.
- `lib/features/player/widgets/loop_config_sheet.dart`: Modal sheet for Count, Timer, A-B.
- `lib/features/library/library_screen.dart`: Track library UI with "Loop this sound".
- `lib/features/mixes/mix_controller.dart`: MixController with play/stop/volume/save/delete.
- `lib/features/mixes/mixes_screen.dart`: Mixes list, live volume sliders, create sheet.
- `test/brown_noise_test.dart`: DSP validation tests.
- `test/loop_controller_test.dart`: Loop controller tests for all modes.
- `tool/render_wav.dart`: 30s classic brown WAV generator.

## What Works
- All loop modes: Off, Forever, Count, Duration (fadeout & restore), A-B (near-gapless).
- Dual-voice audio engine, persistent loop configs, desktop 'L' shortcut.
- Mixes: create, list, delete (swipe), play (noise + optional track), live volume sliders.
- DB v3 with Tracks, ItemLoopConfigs, and Mixes tables with migrations.

## What's Next
- TODO: Track picker in create-mix sheet (select from library).
- TODO: PlayerController.setVolume for mix track volume control.
- Stats screen, Settings screen (theme toggle), Home screen (recently played).
- Search screen.
