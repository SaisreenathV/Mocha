# Mocha - Project Notes

## Files
- `lib/domain/`: `noise_params.dart`, `loop_config.dart`, `saved_mix.dart`, `eq_config.dart`, `lrc_parser.dart`, `audio_engine.dart`.
- `lib/audio/`: `volume_controller.dart`, `soloud_audio_engine.dart`, `loop_controller.dart`.
- `lib/platform/`: `mocha_audio_handler.dart` (MPRIS), `linux_tray_service.dart` (Tray & WindowManager).
- `lib/data/database.dart`: Drift DB (Tracks, LoopConfigs, SavedMixes, EqSettings, ListeningSessions v6).
- `lib/features/`: Noise studio, Player, Library, Mixes, EQ, Lyrics, Stats.
- `packaging/linux/mocha.desktop`: XDG desktop entry for Linux integration.
- `tool/`: `build_appimage.sh` (AppImage builder), `render_wav.dart`.
- `test/`: `brown_noise_test.dart`, `loop_controller_test.dart`, `lrc_parser_test.dart`.

## What Works
- MPRIS integration: separate Play, Pause (never starts playback), PlayPause, Next, Previous, metadata & loop status.
- System tray with Show, Play/Pause, Quit, and close-to-tray window management.
- Drag & Drop file import onto the window (`desktop_drop` with visual feedback & validation).
- Desktop shortcuts: Space (toggle), Left/Right (±10s seek), L (loop), Ctrl+K (search), ignoring text input focus.
- Linux packaging: XDG `.desktop` file and self-contained `build_appimage.sh` script.
- Synced lyrics with sidecar `.lrc` and tap-to-seek; listening sessions & stats screen (bar widgets).
- 8-band EQ on global bus, queue crossfade (0-12s), 1-tap mixes, sleep/pomodoro timers.

## What's Next
- Settings screen (theme toggle espresso/latte, default audio settings).
- Home screen (recently played mixes & sounds).
- Search screen.
