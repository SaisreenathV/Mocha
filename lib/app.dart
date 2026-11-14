import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/shell/adaptive_shell.dart';
import 'core/theme/mocha_theme.dart';
import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/mixes/mixes_screen.dart';
import 'features/noise/noise_studio_screen.dart';
import 'features/placeholder_screen.dart';
import 'features/stats/stats_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const PlaceholderScreen(title: 'Search'),
          ),
          GoRoute(
            path: '/library',
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: '/noise',
            builder: (context, state) => const NoiseStudioScreen(),
          ),
          GoRoute(
            path: '/mixes',
            builder: (context, state) => const MixesScreen(),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const PlaceholderScreen(title: 'Settings'),
          ),
        ],
      ),
    ],
  );
});

final uiScaleProvider = StateProvider<double>((ref) => 1.0);

class MochaApp extends ConsumerWidget {
  const MochaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final uiScale = ref.watch(uiScaleProvider);

    return MaterialApp.router(
      title: 'Mocha',
      debugShowCheckedModeBanner: false,
      theme: MochaTheme.latteTheme,
      darkTheme: MochaTheme.espressoTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(uiScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
