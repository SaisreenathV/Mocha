import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../data/providers.dart';

final statsFutureProvider = FutureProvider.autoDispose((ref) async {
  final db = ref.watch(databaseProvider);
  final weekSec = await db.getTotalSecondsThisWeek();
  final longestSec = await db.getLongestSessionSeconds();
  final streak = await db.getCurrentStreakDays();
  final topSounds = await db.getTopSounds(limit: 5);

  return (
    weekSeconds: weekSec,
    longestSeconds: longestSec,
    streakDays: streak,
    topSounds: topSounds,
  );
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final m = (totalSeconds / 60).floor();
    final h = (m / 60).floor();
    final remM = m % 60;
    if (h == 0) return '${remM}m';
    return '${h}h ${remM}m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsFutureProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Listening Stats')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading stats: $e')),
        data: (stats) {
          final maxSoundSec = stats.topSounds.isEmpty
              ? 1
              : stats.topSounds.map((s) => s.totalSeconds).reduce((a, b) => a > b ? a : b);

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(statsFutureProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.calendar_today_rounded,
                        title: 'This Week',
                        value: _formatDuration(stats.weekSeconds),
                        color: cs.primaryContainer,
                        textColor: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.timelapse_rounded,
                        title: 'Longest',
                        value: _formatDuration(stats.longestSeconds),
                        color: cs.secondaryContainer,
                        textColor: cs.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Daily Streak',
                  value: '${stats.streakDays} ${stats.streakDays == 1 ? 'day' : 'days'}',
                  color: cs.tertiaryContainer,
                  textColor: cs.onTertiaryContainer,
                  subtitle: stats.streakDays > 0
                      ? 'Keep listening daily to build your streak!'
                      : 'Listen today to start your streak!',
                ),
                const SizedBox(height: 24),

                // Top 5 Sounds (Simple bar widgets, no chart packages)
                Text(
                  'Top 5 Sounds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your most played audio and ambient sounds by listening time.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),

                if (stats.topSounds.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No sound sessions recorded yet.\nSessions are saved when playback stops.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                  )
                else
                  ...stats.topSounds.map((sound) {
                    final fraction = maxSoundSec > 0
                        ? (sound.totalSeconds / maxSoundSec).clamp(0.05, 1.0)
                        : 0.05;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  sound.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${_formatDuration(sound.totalSeconds)} (${sound.sessionCount}x)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Custom simple bar widget
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final barWidth = constraints.maxWidth * fraction;
                              return Stack(
                                children: [
                                  Container(
                                    height: 10,
                                    width: constraints.maxWidth,
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  Container(
                                    height: 10,
                                    width: barWidth,
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color textColor;
  final String? subtitle;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.textColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: textColor, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
