# Mocha ☕

A modern, offline-first Flutter desktop (Linux) and mobile (Android) audio app for pure generated brown noise, layered soundscapes, and offline audio playback with advanced looping, equalizer, synced lyrics, listening statistics, and deep desktop integration.

---

## ✨ Features

- **Pure Brown Noise Synthesizer:** Mathematically generated brown noise via leaky integration with customizable low-frequency rumble depth, high-cut filter, warmth boost, and stereo spread.
- **Real FFT Spectrum Visualizer:** Animated frequency spectrum analyzer computed directly from the real rendered audio buffer using a Radix-2 Cooley-Tukey FFT with Hanning windowing (no synthetic formulas).
- **Interactive Depth Dial:** Custom rotational dial for intuitive, low-end rumble corner frequency adjustment across the Home screen and Noise Studio.
- **Layered Soundscape Mixes:** Combine generated brown noise with up to 3 concurrent looping environmental sounds (rain, stream, birds, etc.) with independent voice levels and 1-tap restore.
- **Advanced Looping Engine:** Off, Loop Forever, Loop N Count, Loop Duration, and seamless A-B sub-track segment looping.
- **Master Equalizer & Crossfade:** Global bus 8-band parametric EQ (60 Hz to 15 kHz) with Flat, Bass Boost, Vocal, and Night presets. Smooth 0–12s queue crossfading.
- **Synced Lyrics (.lrc):** Fast binary-search LRC parser with automatic sidecar `.lrc` file detection, smooth auto-scrolling, active line highlighting, and tap-to-seek.
- **Offline Listening Stats:** Drift SQLite database tracking weekly listening duration, longest session, daily focus streaks, and top 5 sounds via custom lightweight bar widgets.
- **Linux Desktop Integration:**
  - **MPRIS 2:** D-Bus media controls with strict play/pause separation, metadata, and loop status.
  - **System Tray:** Tray icon with Show, Play/Pause, Quit, and close-to-tray window management.
  - **Drag & Drop:** Drop audio files directly onto the app window to import into your library.
  - **Keyboard Shortcuts:** Global shortcuts for Space (play/pause), Left/Right (±10s seek), L (loop), and Ctrl+K (search), automatically disabled during text input.

---

## 🏗️ Architecture & Technology Stack

- **Framework:** Flutter (Material 3 Latte light and Espresso dark themes)
- **State Management:** Riverpod (`StateNotifierProvider`, `NotifierProvider`, `FutureProvider`)
- **Navigation:** `go_router` with responsive `AdaptiveShell` (navigation rail for desktop/wide displays, bottom navigation for mobile)
- **Audio Engine:** `flutter_soloud` native audio engine with global bus filtering and multi-voice isolate rendering
- **Database:** `drift` + `sqlite3` for offline persistence of tracks, loop configurations, soundscapes, EQ presets, and listening sessions
- **Offline-First Assets:** Bundled local fonts and assets (zero runtime Google Fonts network calls)

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>= 3.24.0)
- Linux build dependencies (for desktop):
  ```bash
  sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libasound2-dev libayatana-appindicator3-dev
  ```

### Code Generation & Database Setup

Before building or running the project, generate the Drift database and schema files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Running Tests

Run the full suite of unit tests for DSP synthesis, loop controllers, and the LRC parser:

```bash
flutter test
```

---

## 📦 Building for Production

### Linux Desktop Native Build

To build the standalone release binary for Linux:

```bash
flutter build linux --release
```

The output executable will be placed in `build/linux/x64/release/bundle/`.

### Linux AppImage Packaging

Mocha includes an automated script to generate a portable, standalone Linux AppImage containing all native libraries, desktop entry, and icon:

```bash
chmod +x tool/build_appimage.sh
./tool/build_appimage.sh
```

The resulting `Mocha-x86_64.AppImage` will be placed in `build/appimage/`.

### Android APK Build

To compile a release APK for Android:

```bash
flutter build apk --release
```

---

## ⚠️ Known Limitations

1. **MPRIS on Linux:** The MPRIS 2 D-Bus interface requires an active desktop session bus (standard on GNOME, KDE Plasma, XFCE, and modern Wayland/X11 compositors). It is gracefully disabled in headless environments.
2. **Native Audio Bindings:** The `flutter_soloud` engine requires native audio device access (`libasound` / ALSA / PulseAudio / PipeWire).
3. **Offline Lyrics:** Synced lyrics require an LRC file placed with matching filename next to the audio track (e.g., `song.mp3` and `song.lrc`).
