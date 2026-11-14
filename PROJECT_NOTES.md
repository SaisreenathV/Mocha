# Mocha - Project Notes

## Architecture
- `lib/domain/`: DSP (`noise_params.dart`), Looping (`loop_config.dart`), Soundscapes (`saved_mix.dart`), EQ (`eq_config.dart`), Lyrics (`lrc_parser.dart`), Audio Engine interface (`audio_engine.dart`).
- `lib/audio/`: `volume_controller.dart`, `soloud_audio_engine.dart`, `loop_controller.dart`, FFT analyzer (`spectrum_analyzer.dart`).
- `lib/platform/`: `mocha_audio_handler.dart` (MPRIS 2 D-Bus), `linux_tray_service.dart` (Tray & close-to-tray).
- `lib/data/database.dart`: Drift SQLite DB v6 (Tracks, ItemLoopConfigs, Mixes, SavedMixes, EqSettings, ListeningSessions).
- `lib/features/`: Home hero card, Noise Studio, Player & MiniPlayer, Library, Mixes, EQ, Lyrics, Stats.
- `packaging/linux/`: `mocha.desktop`, `tool/build_appimage.sh` for AppImage builds.
- `test/`: `brown_noise_test.dart`, `loop_controller_test.dart`, `lrc_parser_test.dart`.

## What Works
- **Brown Noise & FFT:** Pure Dart synthesis with leaky integration; animated frequency spectrum computed from real audio buffer using Radix-2 Cooley-Tukey FFT with Hanning window; interactive rotational DepthDial.
- **Audio & Soundscapes:** SoLoud engine with 8-band parametric EQ, 0-12s crossfade, VolumeController (sleep fade & Pomodoro ducks), and 1-tap soundscape restore (brown noise + 3 layered sounds).
- **Looping & Lyrics:** 5 loop modes (off, forever, count, duration, A-B segment) and synced LRC parser with sidecar file detection, tap-to-seek, and line highlighting.
- **Offline Stats:** Drift SQLite database recording listening sessions >= 5s on stop; custom lightweight bar widgets for weekly duration, streak, and top sounds.
- **Linux Integration:** MPRIS 2 D-Bus service, system tray with close-to-tray, window drag-and-drop file import, Space/Seek/Loop shortcuts, and AppImage build script.
- **Polish & A11y:** Hero transitions between Home card and Noise Studio; designed empty/error/permission-denied state views; full Semantics labels and scalable typography; offline-first bundled assets.

## Status
- All 15 chunks fully implemented and verified. Production-ready for Linux desktop and Android mobile.
