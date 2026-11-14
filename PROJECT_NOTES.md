# Mocha - Project Notes

## Files
- `lib/domain/noise_params.dart`, `loop_config.dart`, `saved_mix.dart`, `eq_config.dart`, `audio_engine.dart`.
- `lib/audio/volume_controller.dart`: single VolumeController (volume = userVolume x sleepFade x breakDuck).
- `lib/audio/soloud_audio_engine.dart`: SoLoud dual-voice + 3 layered Sounds + global 8-band EQ & crossfade.
- `lib/audio/loop_controller.dart`: Count, Duration, A-B loop modes.
- `lib/platform/mocha_audio_handler.dart`: AudioService handler, master & noise volume routing.
- `lib/data/database.dart`: Drift database (Tracks, ItemLoopConfigs, SavedMixes, EqSettingsTable v5).
- `lib/features/noise/`: Noise studio, presets, depth dial.
- `lib/features/player/`: Player controller (queue crossfade), MiniPlayer, NowPlaying, LoopConfigSheet, TimerSheet.
- `lib/features/library/`: Library screen with import & Sound tagging.
- `lib/features/mixes/`: MixController (save/restore in 1 tap) & MixesScreen with 3 layered sounds.
- `lib/features/eq/`: EqController & EqScreen (8 real bands, Flat/Bass boost/Vocal/Night presets, 0-12s crossfade).

## What Works
- Single VolumeController: final volume = user volume x sleepFade x breakDuck; no other setVolume callers.
- Sleep timer (minutes or end-of-track, 30s fade) & Pomodoro (25/5 min, 15% duck).
- SavedMixes: saves noise params + 3 layered looping Sounds with volumes & loop states (1-tap restore).
- Real 8-band multi-band Equalizer on global bus (affects noise and audio files), ±12 dB sliders.
- Presets: Flat, Bass boost, Vocal, Night with SQLite settings persistence (v5).
- Queue track crossfade: 0 to 12 seconds smooth volume blend (inactive while looping).

## What's Next
- Stats screen (listening history & statistics).
- Settings screen (theme toggle espresso/latte, default audio settings).
- Home screen (recently played mixes & sounds).
- Search screen.
