import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'mocha_audio_handler.dart';

class LinuxTrayService with TrayListener, WindowListener {
  final MochaAudioHandler _audioHandler;
  bool closeToTray = false;
  bool _initialized = false;

  LinuxTrayService(this._audioHandler);

  Future<void> init() async {
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) return;
    if (_initialized) return;
    _initialized = true;

    try {
      await windowManager.ensureInitialized();
      windowManager.addListener(this);
      await windowManager.setPreventClose(true);

      final windowOptions = WindowOptions(
        size: const Size(1020, 720),
        minimumSize: const Size(540, 600),
        center: true,
        title: 'Mocha',
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      trayManager.addListener(this);
      // Use fallback icon if custom asset is not provided
      await trayManager.setIcon(
        Platform.isWindows ? 'images/tray_icon.ico' : 'assets/icons/mocha_tray.png',
      );
      await trayManager.setToolTip('Mocha');
      await _updateContextMenu();
    } catch (_) {
      // In tests or headless environments, silently proceed
    }
  }

  Future<void> _updateContextMenu() async {
    final menu = Menu(
      items: [
        MenuItem(
          key: 'show',
          label: 'Show Mocha',
        ),
        MenuItem(
          key: 'play_pause',
          label: 'Play / Pause',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: 'Quit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show':
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'play_pause':
        await _audioHandler.playPause();
        break;
      case 'quit':
        await trayManager.destroy();
        await windowManager.destroy();
        exit(0);
    }
  }

  @override
  void onWindowClose() async {
    if (closeToTray) {
      await windowManager.hide();
    } else {
      await trayManager.destroy();
      await windowManager.destroy();
      exit(0);
    }
  }

  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
  }
}

final linuxTrayServiceProvider = Provider<LinuxTrayService>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return LinuxTrayService(handler);
});
