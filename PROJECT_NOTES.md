# Mocha - Project Notes

## Files
- `lib/domain/`: `noise_params.dart`, `loop_config.dart`, `saved_mix.dart`, `eq_config.dart`, `lrc_parser.dart`, `audio_engine.dart`.
- `lib/audio/`: `volume_controller.dart`, `soloud_audio_engine.dart`, `loop_controller.dart`.
- `lib/platform/mocha_audio_handler.dart`: AudioService background handler.
- `lib/data/database.dart`: Drift DB (Tracks, LoopConfigs, SavedMixes, EqSettings, ListeningSessions v6).
- `lib/features/noise/`: Noise studio, presets, depth dial.
- `lib/features/player/`: Player controller, MiniPlayer, NowPlaying, LoopConfigSheet, TimerSheet.
- `lib/features/library/`: Library screen with import & Sound tagging.
- `lib/features/mixes/`: MixController (1-tap restore) & MixesScreen (3 layered sounds).
- `lib/features/eq/`: EqController & EqScreen (8 real bands, 4 presets, 0-12s crossfade).
- `lib/features/lyrics/`: Full-screen synced LyricsScreen with sidecar .lrc detection & tap-to-seek.
- `lib/features/stats/`: SessionRecorder & StatsScreen (this week, longest, streak, top 5 sounds).
- `test/`: `brown_noise_test.dart`, `loop_controller_test.dart`, `lrc_parser_test.dart`.

## What Works
- LRC parser with full unit tests, sidecar `.lrc` detection, and binary-search line indexing.
- Synced lyrics full-screen view: active line highlighting, auto-centering scroll, and tap-to-seek.
- ListeningSessions table v6: automatically records sessions (>= 5s) when playback stops.
- Stats screen: Time this week, longest session, current daily streak, and top 5 sounds bar widgets (no chart pkgs).
- 8-band global EQ, 4 presets, 0-12s crossfade, 1-tap mixes, sleep/pomodoro timers, dual-voice engine.

## What's Next
- Settings screen (theme toggle espresso/latte, default audio settings).
- Home screen (recently played mixes & sounds).
- Search screen.
