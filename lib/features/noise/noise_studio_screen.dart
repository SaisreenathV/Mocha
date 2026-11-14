import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/noise_params.dart';
import 'noise_controller.dart';
import 'widgets/depth_dial.dart';
import 'widgets/real_spectrum_visualizer.dart';

class NoiseStudioScreen extends ConsumerStatefulWidget {
  const NoiseStudioScreen({super.key});

  @override
  ConsumerState<NoiseStudioScreen> createState() => _NoiseStudioScreenState();
}

class _NoiseStudioScreenState extends ConsumerState<NoiseStudioScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Map<String, NoiseParams> _builtInPresets = {
    'Classic Brown': NoiseParams.classicBrown,
    'Deep Rumble': NoiseParams.deepRumble,
    'Soft Brown': NoiseParams.softBrown,
    'Focus': NoiseParams.focus,
    'Deep Sleep': NoiseParams.deepSleep,
    'Airplane Cabin': NoiseParams.airplaneCabin,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showSavePresetDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Custom Preset'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Preset Name',
            hintText: 'e.g. Cozy Night',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                ref.read(noiseControllerProvider.notifier).saveCustomPreset(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noiseControllerProvider);
    final controller = ref.read(noiseControllerProvider.notifier);
    final theme = Theme.of(context);
    final params = state.params;

    // Logarithmic mapping for cutoff: 80 Hz to 8000 Hz
    final logMin = math.log(80.0);
    final logMax = math.log(8000.0);
    final cutoffRatio = ((math.log(params.cutoffHz.clamp(80.0, 8000.0)) - logMin) / (logMax - logMin))
        .clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noise Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save preset',
            onPressed: () => _showSavePresetDialog(context),
          ),
        ],
      ),
      body: Hero(
        tag: 'brown_noise_card',
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            // Preset Chips
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ..._builtInPresets.entries.map((e) {
                  final isSelected = state.selectedPresetName == e.key;
                  return ChoiceChip(
                    label: Text(e.key),
                    selected: isSelected,
                    onSelected: (_) => controller.selectPreset(e.key, e.value),
                  );
                }),
                ...state.customPresets.entries.map((e) {
                  final isSelected = state.selectedPresetName == e.key;
                  return ChoiceChip(
                    label: Text('${e.key} *'),
                    selected: isSelected,
                    onSelected: (_) => controller.selectPreset(e.key, e.value),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),

            // Pulsing Play Button
            SizedBox(
              height: 140,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    final scale = state.isPlaying ? _pulseAnimation.value : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Material(
                        color: state.isPlaying
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHigh,
                        shape: const CircleBorder(),
                        elevation: state.isPlaying ? 8 : 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => controller.togglePlay(),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Icon(
                              state.isPlaying
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              size: 54,
                              color: state.isPlaying
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Status & Debounce Updating Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.isPlaying ? state.selectedPresetName : 'Stopped',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (state.isUpdating) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Updating...',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Real FFT Spectrum Visualizer computed from rendered buffer
            RealSpectrumVisualizer(
              params: params,
              isPlaying: state.isPlaying,
              numBands: 20,
              height: 52,
            ),
            const SizedBox(height: 24),

            // Depth Dial
            Column(
              children: [
                Text(
                  'Depth (Corner Frequency)',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DepthDial(
                  value: params.depth,
                  onChanged: (v) => controller.updateParam((p) => p.copyWith(depth: v)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Cutoff Log Slider (80 to 8000 Hz)
            _buildSliderRow(
              context: context,
              label: 'Cutoff',
              valueText: '${params.cutoffHz.toStringAsFixed(0)} Hz',
              slider: Slider(
                value: cutoffRatio,
                onChanged: (ratio) {
                  final newHz = math.exp(logMin + ratio * (logMax - logMin));
                  controller.updateParam((p) => p.copyWith(cutoffHz: newHz));
                },
              ),
            ),

            // Warmth Low-Shelf Slider (-6 dB to +6 dB)
            _buildSliderRow(
              context: context,
              label: 'Warmth (180 Hz)',
              valueText: '${params.warmthDb > 0 ? '+' : ''}${params.warmthDb.toStringAsFixed(1)} dB',
              slider: Slider(
                value: params.warmthDb,
                min: -6.0,
                max: 6.0,
                onChanged: (v) => controller.updateParam((p) => p.copyWith(warmthDb: v)),
              ),
            ),

            // Stereo Width Slider (0.0 to 1.0)
            _buildSliderRow(
              context: context,
              label: 'Stereo Width',
              valueText: '${(params.stereoWidth * 100).toStringAsFixed(0)}%',
              slider: Slider(
                value: params.stereoWidth,
                min: 0.0,
                max: 1.0,
                onChanged: (v) => controller.updateParam((p) => p.copyWith(stereoWidth: v)),
              ),
            ),

            // Volume Slider (Instant, no re-render)
            _buildSliderRow(
              context: context,
              label: 'Volume',
              valueText: '${(params.volume * 100).toStringAsFixed(0)}%',
              slider: Slider(
                value: params.volume,
                min: 0.0,
                max: 1.0,
                onChanged: (v) => controller.setVolume(v),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildSliderRow({
    required BuildContext context,
    required String label,
    required String valueText,
    required Widget slider,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text(
                valueText,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}
