import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/noise_params.dart';
import '../eq/eq_screen.dart';
import '../noise/noise_controller.dart';
import '../noise/widgets/depth_dial.dart';
import '../noise/widgets/real_spectrum_visualizer.dart';
import '../stats/stats_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const Map<String, NoiseParams> _quickPresets = {
    'Classic': NoiseParams.classicBrown,
    'Deep Rumble': NoiseParams.deepRumble,
    'Soft': NoiseParams.softBrown,
    'Focus': NoiseParams.focus,
    'Sleep': NoiseParams.deepSleep,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noiseState = ref.watch(noiseControllerProvider);
    final noiseCtrl = ref.read(noiseControllerProvider.notifier);
    final statsAsync = ref.watch(statsFutureProvider);
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mocha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.equalizer_rounded),
            tooltip: 'Equalizer & Crossfade',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const EqScreen(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Listening Stats',
            onPressed: () => context.push('/stats'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          // Hero Brown Noise Card
          Hero(
            tag: 'brown_noise_card',
            child: Material(
              color: Colors.transparent,
              child: Card(
                elevation: noiseState.isPlaying ? 4 : 1,
                color: cs.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: noiseState.isPlaying
                        ? cs.primary.withValues(alpha: 0.5)
                        : cs.outlineVariant.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/noise'),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: noiseState.isPlaying
                                    ? cs.primary
                                    : cs.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.graphic_eq_rounded,
                                size: 20,
                                color: noiseState.isPlaying
                                    ? cs.onPrimary
                                    : cs.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Brown Noise',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    noiseState.isPlaying
                                        ? 'Playing • ${noiseState.selectedPresetName}'
                                        : 'Stopped • Tap to customize',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: noiseState.isPlaying
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Semantics(
                              label: noiseState.isPlaying ? 'Stop Brown Noise' : 'Play Brown Noise',
                              child: IconButton.filled(
                                onPressed: () => noiseCtrl.togglePlay(),
                                icon: Icon(
                                  noiseState.isPlaying
                                      ? Icons.stop_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Real FFT Spectrum Visualizer
                        RealSpectrumVisualizer(
                          params: noiseState.params,
                          isPlaying: noiseState.isPlaying,
                          numBands: 16,
                          height: 48,
                        ),
                        const SizedBox(height: 16),

                        // Depth Dial & Cutoff summary row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Semantics(
                                  label: 'Rumble depth: ${noiseState.params.depth.toStringAsFixed(0)} Hertz',
                                  child: DepthDial(
                                    value: noiseState.params.depth,
                                    size: 88,
                                    onChanged: (v) => noiseCtrl.updateParam((p) => p.copyWith(depth: v)),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Depth Dial',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lowpass Filter',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${noiseState.params.cutoffHz.toStringAsFixed(0)} Hz',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Stereo Width',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${(noiseState.params.stereoWidth * 100).toStringAsFixed(0)}%',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Quick Preset Chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _quickPresets.entries.map((e) {
                            final isSel = noiseState.selectedPresetName == e.key;
                            return ChoiceChip(
                              label: Text(e.key, style: const TextStyle(fontSize: 12)),
                              selected: isSel,
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => noiseCtrl.selectPreset(e.key, e.value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Daily Streak & Activity Card
          Card(
            color: cs.surfaceContainerLow,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: statsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => const Text('Offline stats available'),
                data: (s) {
                  final minutes = (s.weekSeconds / 60).round();
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Daily Streak',
                        value: '${s.streakDays}d 🔥',
                        caption: 'Consistent focus',
                      ),
                      Container(height: 36, width: 1, color: cs.outlineVariant),
                      _StatColumn(
                        label: 'This Week',
                        value: minutes < 60 ? '${minutes}m' : '${(minutes / 60).toStringAsFixed(1)}h',
                        caption: 'Total listening',
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Navigation Grid
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.layers_outlined,
                  title: 'Soundscapes',
                  subtitle: 'Layered mixes',
                  onTap: () => context.push('/mixes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.audio_file_outlined,
                  title: 'Library',
                  subtitle: 'Offline audio files',
                  onTap: () => context.push('/library'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String caption;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      child: Column(
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          Text(caption, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              Icon(icon, size: 28, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
