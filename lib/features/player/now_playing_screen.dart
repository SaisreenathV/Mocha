import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/loop_controller.dart';
import '../../domain/loop_config.dart';
import '../eq/eq_screen.dart';
import 'player_controller.dart';
import 'widgets/loop_config_sheet.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  IconData _getLoopIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return Icons.repeat_rounded;
      case LoopMode.forever:
        return Icons.repeat_one_rounded;
      case LoopMode.count:
        return Icons.looks_one_rounded;
      case LoopMode.duration:
        return Icons.timer_rounded;
      case LoopMode.ab:
        return Icons.all_inclusive_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final loopController = ref.read(loopControllerProvider);
    final activeLoopMode = ref.watch(activeLoopModeProvider);
    final theme = Theme.of(context);
    final track = state.currentTrack;

    if (track == null) {
      return const Scaffold(body: Center(child: Text('No track playing')));
    }

    final totalMs = state.duration.inMilliseconds.toDouble();
    final currentMs = state.position.inMilliseconds.toDouble().clamp(0.0, totalMs > 0 ? totalMs : 1.0);
    final isLoopActive = activeLoopMode != LoopMode.off;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Now Playing'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.equalizer_rounded),
            tooltip: 'Equalizer & Crossfade',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EqScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Loop Settings',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => LoopConfigSheet(track: track),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Artwork Placeholder
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Icon(
                      track.isSound ? Icons.graphic_eq_rounded : Icons.album_rounded,
                      size: 96,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),

              // Title & Artist
              Column(
                children: [
                  Text(
                    track.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track.artist ?? (track.album ?? 'Unknown Artist'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              // Seek Slider & Times
              Column(
                children: [
                  Slider(
                    value: currentMs,
                    max: totalMs > 0 ? totalMs : 1.0,
                    onChanged: (val) {
                      controller.seek(Duration(milliseconds: val.toInt()));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(state.position), style: theme.textTheme.labelMedium),
                        Text(_formatDuration(state.duration), style: theme.textTheme.labelMedium),
                      ],
                    ),
                  ),
                ],
              ),

              // Controls (Speed, Loop, Play/Pause, Forward)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
                      final nextIdx = (speeds.indexOf(state.speed) + 1) % speeds.length;
                      controller.setSpeed(speeds[nextIdx]);
                    },
                    child: Text('${state.speed}x', style: theme.textTheme.titleMedium),
                  ),
                  IconButton(
                    icon: Icon(
                      _getLoopIcon(activeLoopMode),
                      size: 28,
                      color: isLoopActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Mode: ${activeLoopMode.name}. Long press to configure.',
                    onPressed: () async {
                      final next = await loopController.toggleLoop(track.id, isSound: track.isSound);
                      ref.read(activeLoopModeProvider.notifier).state = next;
                    },
                  ),
                  Material(
                    color: theme.colorScheme.primary,
                    shape: const CircleBorder(),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => controller.togglePlay(),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(
                          state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 40,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded),
                    onPressed: () {
                      controller.seek(state.position + const Duration(seconds: 10));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
