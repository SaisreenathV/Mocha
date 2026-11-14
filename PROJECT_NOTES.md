# Mocha - Project Notes

## Files
- `pubspec.yaml`: Dependencies and Material 3 config.
- `lib/main.dart`: Entrypoint with DB, AudioService, and Riverpod.
- `lib/app.dart`: App routing with ShellRoute.
- `lib/core/theme/mocha_theme.dart`: Material 3 espresso/latte themes.
- `lib/core/shell/adaptive_shell.dart`: Adaptive navigation shell with embedded MiniPlayer.
- `lib/domain/noise_params.dart`: Brown noise parameter model.
- `lib/domain/audio_engine.dart`: AudioEngine contract (noise + file voices).
- `lib/audio/dsp/brown_noise_synthesizer.dart`: Pure-Dart DSP synthesizer.
- `lib/audio/soloud_audio_engine.dart`: SoLoud dual-voice playback engine.
- `lib/platform/mocha_audio_handler.dart`: AudioService handler with session interruptions.
- `lib/data/database.dart`: Drift database with Tracks table.
- `lib/data/importer.dart`: File/folder importer with Isolate tag parsing.
- `lib/data/providers.dart`: Database, importer, and tracks stream providers.
- `lib/features/noise/noise_studio_screen.dart`: Noise studio controls & depth dial.
- `lib/features/player/player_controller.dart`: Audio file player controller & position stream.
- `lib/features/player/mini_player.dart`: Persistent mini player with progress bar.
- `lib/features/player/now_playing_screen.dart`: Full now playing modal with seek and speed.
- `lib/features/library/library_screen.dart`: Track library UI with instant playback.
- `test/brown_noise_test.dart`: DSP validation tests.
- `tool/render_wav.dart`: 30s classic brown WAV generator.

## What Works
- Dual-voice SoLoud audio engine: independent brown noise and file playback channels.
- Master `pauseAll()` for audio session interruptions and background notifications.
- Persistent MiniPlayer mounted above mobile bottom bar and at bottom of desktop content.
- NowPlayingScreen with seek slider, duration formatting, and speed multiplier selector.
- Tap-to-play in library with reactive active track highlighting.

## What's Next
- Chunk 8: Audio looping controls (seamless loop toggle, A/B loop markers).
- Layered soundscapes (combining brown noise generator and looping audio tracks).
