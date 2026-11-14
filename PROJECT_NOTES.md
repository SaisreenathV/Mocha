# Mocha - Project Notes

## Files
- `lib/domain/noise_params.dart`, `loop_config.dart`, `saved_mix.dart`, `audio_engine.dart`.
- `lib/audio/volume_controller.dart`: single VolumeController (volume = userVolume x sleepFade x breakDuck).
- `lib/audio/soloud_audio_engine.dart`: SoLoud dual-voice + up to 3 layered Sound voices.
- `lib/audio/loop_controller.dart`: Count, Duration, A-B loop modes.
- `lib/platform/mocha_audio_handler.dart`: AudioService handler, master & noise volume routing.
- `lib/data/database.dart`: Drift database (Tracks, ItemLoopConfigs, SavedMixes v4).
- `lib/features/noise/`: Noise studio, presets, depth dial.
- `lib/features/player/`: Player controller, MiniPlayer, NowPlaying, LoopConfigSheet, TimerSheet.
- `lib/features/library/`: Library screen with import & Sound tagging.
- `lib/features/mixes/`: MixController (save/restore in 1 tap) & MixesScreen with 3 layered sounds.

## What Works
- Single VolumeController: final volume = user volume x sleepFade x breakDuck; no other setVolume callers.
- Sleep timer: minutes or end-of-track, 30s linear fade then pause, with volume restore & cancel.
- Pomodoro: 25 min focus / 5 min break, ducking to 15% during breaks.
- SavedMixes: saves noise params + up to 3 layered looping Sounds with individual volumes & loop states.
- 1-tap restore of complete soundscapes from SavedMixes SQLite table (v4).

## What's Next
- Stats screen (listening history & statistics).
- Settings screen (theme toggle espresso/latte, default audio settings).
- Home screen (recently played mixes & sounds).
- Search screen.
