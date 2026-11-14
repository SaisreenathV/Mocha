# Mocha - Project Notes

## Architecture
- `lib/domain/`: DSP (`noise_params.dart`), Looping (`loop_config.dart`), Soundscapes (`saved_mix.dart`), EQ (`eq_config.dart`), Lyrics (`lrc_parser.dart`), Audio Engine interface (`audio_engine.dart`).
- `lib/audio/`: `volume_controller.dart`, `soloud_audio_engine.dart`, `loop_controller.dart`, FFT analyzer (`spectrum_analyzer.dart`).
- `lib/platform/`: `mocha_audio_handler.dart` (MPRIS 2 D-Bus & Android media notification), `linux_tray_service.dart`.
- `lib/data/database.dart`: Drift SQLite DB v6 (Tracks, ItemLoopConfigs, Mixes, SavedMixes, EqSettings, ListeningSessions).
- `lib/features/`: Home hero card, Noise Studio, Player & MiniPlayer, Library, Mixes, EQ, Lyrics, Stats.
- `android/`: `AudioServiceActivity` integration, background playback foreground service, SDK 36 compatibility.
- `packaging/linux/`: `mocha.desktop`, `tool/build_appimage.sh` for AppImage builds.

## What Works
- **Brown Noise & FFT:** Pure Dart synthesis with leaky integration; animated frequency spectrum computed from real audio buffer using Radix-2 Cooley-Tukey FFT; interactive rotational DepthDial.
- **Audio & Soundscapes:** SoLoud engine with 8-band parametric EQ, 0-12s crossfade, VolumeController (sleep fade & Pomodoro ducks), and 1-tap soundscape restore.
- **Looping & Lyrics:** 5 loop modes and synced LRC parser with sidecar file detection, tap-to-seek, and line highlighting.
- **Offline Stats:** Drift SQLite database recording listening sessions >= 5s on stop; custom weekly duration, streak, and top sounds widgets.
- **Linux & Android Multiplatform:** Linux MPRIS 2 D-Bus + tray; Android `AudioService` foreground notification & media session; Release APK built successfully.

## Status
- All 15 chunks fully implemented and verified. Both Linux desktop and Android release APK builds ready.
