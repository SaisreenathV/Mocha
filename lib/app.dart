import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/shell/adaptive_shell.dart';
import 'core/theme/mocha_theme.dart';
import 'features/noise/noise_studio_screen.dart';
import 'features/placeholder_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const PlaceholderScreen(title: 'Home'),
          ),
          GoRoute(
            path: '/search',
            builder: (context, state) => const PlaceholderScreen(title: 'Search'),
          ),
          GoRoute(
            path: '/library',
            builder: (context, state) => const PlaceholderScreen(title: 'Library'),
          ),
          GoRoute(
            path: '/noise',
            builder: (context, state) => const NoiseStudioScreen(),
          ),
          GoRoute(
            path: '/mixes',
            builder: (context, state) => const PlaceholderScreen(title: 'Mixes'),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const PlaceholderScreen(title: 'Stats'),
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

class MochaApp extends ConsumerWidget {
  const MochaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Mocha',
      debugShowCheckedModeBanner: false,
      theme: MochaTheme.latteTheme,
      darkTheme: MochaTheme.espressoTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
