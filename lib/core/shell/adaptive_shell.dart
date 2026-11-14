import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../audio/loop_controller.dart';
import '../../features/player/mini_player.dart';
import '../../features/player/player_controller.dart';

class AdaptiveShell extends ConsumerWidget {
  final Widget child;

  const AdaptiveShell({
    super.key,
    required this.child,
  });

  int _getBottomNavIndex(String path) {
    if (path.startsWith('/search')) return 1;
    if (path.startsWith('/library')) return 2;
    return 0;
  }

  int _getSidebarNavIndex(String path) {
    if (path.startsWith('/noise')) return 1;
    if (path.startsWith('/library')) return 2;
    if (path.startsWith('/mixes')) return 3;
    if (path.startsWith('/stats')) return 4;
    if (path.startsWith('/settings')) return 5;
    return 0;
  }

  void _onBottomNavTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/library');
        break;
    }
  }

  void _onSidebarNavTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/noise');
        break;
      case 2:
        context.go('/library');
        break;
      case 3:
        context.go('/mixes');
        break;
      case 4:
        context.go('/stats');
        break;
      case 5:
        context.go('/settings');
        break;
    }
  }

  KeyEventResult _handleDesktopKeyEvent(FocusNode node, KeyEvent event, WidgetRef ref) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyL) {
      final focusedContext = FocusManager.instance.primaryFocus?.context;
      if (focusedContext != null) {
        final isEditing = focusedContext.findAncestorWidgetOfExactType<EditableText>() != null;
        if (isEditing) {
          return KeyEventResult.ignored;
        }
      }

      final activeTrack = ref.read(playerControllerProvider).currentTrack;
      if (activeTrack != null) {
        ref.read(loopControllerProvider).toggleLoop(
          activeTrack.id,
          isSound: activeTrack.isSound,
        ).then((next) {
          ref.read(activeLoopModeProvider.notifier).state = next;
        });
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = GoRouterState.of(context).uri.path;
    final isWide = MediaQuery.sizeOf(context).width >= 700;

    Widget shellContent;

    if (isWide) {
      shellContent = Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _getSidebarNavIndex(path),
              onDestinationSelected: (idx) => _onSidebarNavTapped(context, idx),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Icon(Icons.coffee, size: 28),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.graphic_eq_outlined),
                  selectedIcon: Icon(Icons.graphic_eq),
                  label: Text('Noise'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: Text('Library'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('Mixes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: Text('Stats'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: child),
                  const MiniPlayer(),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      shellContent = Scaffold(
        body: child,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            NavigationBar(
              selectedIndex: _getBottomNavIndex(path),
              onDestinationSelected: (idx) => _onBottomNavTapped(context, idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: 'Library',
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return Focus(
        autofocus: true,
        onKeyEvent: (node, event) => _handleDesktopKeyEvent(node, event, ref),
        child: shellContent,
      );
    }

    return shellContent;
  }
}
