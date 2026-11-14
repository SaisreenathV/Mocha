import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../audio/loop_controller.dart';
import '../../data/providers.dart';
import '../../features/noise/noise_controller.dart';
import '../../features/player/mini_player.dart';
import '../../features/player/player_controller.dart';
import '../../features/stats/session_recorder.dart';
import '../../platform/linux_tray_service.dart';

class AdaptiveShell extends ConsumerStatefulWidget {
  final Widget child;

  const AdaptiveShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends ConsumerState<AdaptiveShell> {
  final FocusNode _keyboardFocusNode = FocusNode();
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(linuxTrayServiceProvider).init();
      });
    }
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

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

  KeyEventResult _handleDesktopKeyEvent(FocusNode node, KeyEvent event, BuildContext context) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Check if a text field has focus
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext != null) {
      final isEditing = focusedContext.findAncestorWidgetOfExactType<EditableText>() != null;
      if (isEditing) {
        return KeyEventResult.ignored;
      }
    }

    // Ctrl+K -> Search shortcut
    final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.keyK) {
      context.go('/search');
      return KeyEventResult.handled;
    }

    // Ctrl + / Ctrl - / Ctrl 0 -> UI Scaling
    if (isCtrlOrCmd && (event.logicalKey == LogicalKeyboardKey.equal || event.logicalKey == LogicalKeyboardKey.add)) {
      ref.read(uiScaleProvider.notifier).update((s) => (s + 0.15).clamp(0.8, 2.5));
      return KeyEventResult.handled;
    }
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.minus) {
      ref.read(uiScaleProvider.notifier).update((s) => (s - 0.15).clamp(0.8, 2.5));
      return KeyEventResult.handled;
    }
    if (isCtrlOrCmd && event.logicalKey == LogicalKeyboardKey.digit0) {
      ref.read(uiScaleProvider.notifier).state = 1.0;
      return KeyEventResult.handled;
    }

    // Space -> Toggle Play / Pause
    if (event.logicalKey == LogicalKeyboardKey.space) {
      final playerState = ref.read(playerControllerProvider);
      if (playerState.currentTrack != null) {
        ref.read(playerControllerProvider.notifier).togglePlay();
      } else {
        ref.read(noiseControllerProvider.notifier).togglePlay();
      }
      return KeyEventResult.handled;
    }

    // Left Arrow -> Seek -10s
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final playerState = ref.read(playerControllerProvider);
      if (playerState.currentTrack != null) {
        final newPos = playerState.position - const Duration(seconds: 10);
        ref.read(playerControllerProvider.notifier).seek(
              newPos > Duration.zero ? newPos : Duration.zero,
            );
        return KeyEventResult.handled;
      }
    }

    // Right Arrow -> Seek +10s
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final playerState = ref.read(playerControllerProvider);
      if (playerState.currentTrack != null) {
        final newPos = playerState.position + const Duration(seconds: 10);
        ref.read(playerControllerProvider.notifier).seek(
              newPos < playerState.duration ? newPos : playerState.duration,
            );
        return KeyEventResult.handled;
      }
    }

    // L -> Toggle Loop
    if (event.logicalKey == LogicalKeyboardKey.keyL) {
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

  Future<void> _handleDroppedFiles(List<String> rawPaths) async {
    const supportedExts = {'mp3', 'wav', 'flac', 'ogg', 'm4a', 'aac', 'opus'};
    final audioPaths = rawPaths.where((p) {
      final ext = p.split('.').last.toLowerCase();
      return supportedExts.contains(ext);
    }).toList();

    if (audioPaths.isNotEmpty) {
      final count = await ref.read(importerProvider).importFiles(audioPaths);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count audio file${count == 1 ? '' : 's'}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionRecorderProvider);
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
                  Expanded(child: widget.child),
                  const MiniPlayer(),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      shellContent = Scaffold(
        body: widget.child,
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

    // Wrap in DropTarget for drag-and-drop file import on desktop
    Widget dropWrapped = DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);
        final paths = details.files.map((f) => f.path).toList();
        await _handleDroppedFiles(paths);
      },
      child: Stack(
        children: [
          shellContent,
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.file_download, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Drop audio files to import',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      return Focus(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: (node, event) => _handleDesktopKeyEvent(node, event, context),
        child: dropWrapped,
      );
    }

    return dropWrapped;
  }
}
