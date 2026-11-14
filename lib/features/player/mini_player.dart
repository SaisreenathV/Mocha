import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../audio/loop_controller.dart';
import '../../domain/loop_config.dart';
import 'now_playing_screen.dart';
import 'player_controller.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final loopController = ref.read(loopControllerProvider);
    final activeLoopMode = ref.watch(activeLoopModeProvider);
    final theme = Theme.of(context);

    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final totalMs = state.duration.inMilliseconds;
    final currentMs = state.position.inMilliseconds;
    final progress = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final isLoopingForever = activeLoopMode == LoopMode.forever;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 2.5,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const NowPlayingScreen(),
              );
            },
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: Icon(
                track.isSound ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            title: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              track.artist ?? 'Unknown Artist',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isLoopingForever ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                    size: 24,
                    color: isLoopingForever ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  tooltip: isLoopingForever ? 'Looping forever' : 'Loop off',
                  onPressed: () async {
                    final next = await loopController.toggleLoop(track.id, isSound: track.isSound);
                    ref.read(activeLoopModeProvider.notifier).state = next;
                  },
                ),
                IconButton(
                  icon: Icon(
                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 30,
                  ),
                  onPressed: () => controller.togglePlay(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
