# Mocha - Project Notes

## Files
- `pubspec.yaml`: App dependencies and Material 3 design configuration.
- `lib/main.dart`: App entrypoint initializing ProviderScope.
- `lib/app.dart`: MochaApp configuration with Riverpod and GoRouter routes.
- `lib/core/theme/mocha_theme.dart`: Material 3 espresso dark and latte light themes.
- `lib/core/shell/adaptive_shell.dart`: Responsive shell (bottom bar <700px, rail >=700px).
- `lib/features/placeholder_screen.dart`: Generic placeholder screen for routes.

## What Works
- Material 3 theme switching (espresso dark #1B120D and latte light).
- Adaptive navigation:
  - Width < 700: Bottom NavigationBar (Home, Search, Library).
  - Width >= 700: NavigationRail sidebar (Home, Noise, Library, Mixes, Stats, Settings).
- ShellRoute displays PlaceholderScreen with route titles across all routes.
- ProviderScope and routerProvider are wired.

## What's Next
- Chunk 2: Audio engine integration (flutter_soloud) for brown noise generation.
- Background service integration (audio_service).
- Local database setup (drift) for tracks and mix presets.
