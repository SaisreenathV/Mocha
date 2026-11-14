import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../audio/volume_controller.dart';

class TimerSheet extends ConsumerWidget {
  const TimerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const TimerSheet(),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volumeState = ref.watch(volumeControllerProvider);
    final volumeCtrl = ref.read(volumeControllerProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Sleep & Focus Timers',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Master volume
          Row(
            children: [
              const Icon(Icons.volume_up, size: 20),
              const SizedBox(width: 8),
              Text(
                'Volume: ${(volumeState.finalVolume * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Slider(
                  value: volumeState.userVolume,
                  onChanged: (v) => volumeCtrl.setUserVolume(v),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Sleep Timer section
          Text('Sleep Timer', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Fades out over 30s before pausing audio.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (volumeState.isSleepTimerActive) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.bedtime, color: cs.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      volumeState.isEndOfTrackSleep
                          ? 'Stopping at end of track (30s fade)'
                          : 'Stopping in ${_formatDuration(volumeState.sleepTimerRemaining ?? Duration.zero)}',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => volumeCtrl.cancelSleepTimer(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('15 min'),
                  onPressed: () => volumeCtrl.startSleepTimer(const Duration(minutes: 15)),
                ),
                ActionChip(
                  label: const Text('30 min'),
                  onPressed: () => volumeCtrl.startSleepTimer(const Duration(minutes: 30)),
                ),
                ActionChip(
                  label: const Text('45 min'),
                  onPressed: () => volumeCtrl.startSleepTimer(const Duration(minutes: 45)),
                ),
                ActionChip(
                  label: const Text('60 min'),
                  onPressed: () => volumeCtrl.startSleepTimer(const Duration(minutes: 60)),
                ),
                ActionChip(
                  avatar: const Icon(Icons.music_note, size: 16),
                  label: const Text('End of track'),
                  onPressed: () => volumeCtrl.startEndOfTrackSleepTimer(),
                ),
              ],
            ),
          ],
          const Divider(height: 28),

          // Pomodoro Focus section
          Text('Pomodoro Focus', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            '25 min focus / 5 min break (ducks volume to 15%).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (volumeState.pomodoroPhase != PomodoroPhase.idle) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: volumeState.pomodoroPhase == PomodoroPhase.work
                    ? cs.secondaryContainer
                    : cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    volumeState.pomodoroPhase == PomodoroPhase.work
                        ? Icons.work_outline
                        : Icons.coffee_outlined,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          volumeState.pomodoroPhase == PomodoroPhase.work
                              ? 'Focus Phase'
                              : 'Break Time (15% volume)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(_formatDuration(volumeState.pomodoroRemaining ?? Duration.zero)),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => volumeCtrl.stopPomodoro(),
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ),
          ] else ...[
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Pomodoro (25/5 min)'),
              onPressed: () => volumeCtrl.startPomodoro(),
            ),
          ],
        ],
      ),
    );
  }
}
