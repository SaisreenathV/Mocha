import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/noise_params.dart';
import 'noise_controller.dart';

class NoiseScreen extends ConsumerWidget {
  const NoiseScreen({super.key});

  static const Map<String, NoiseParams> _presets = {
    'Classic Brown': NoiseParams.classicBrown,
    'Deep Rumble': NoiseParams.deepRumble,
    'Soft Brown': NoiseParams.softBrown,
    'Focus': NoiseParams.focus,
    'Deep Sleep': NoiseParams.deepSleep,
    'Airplane Cabin': NoiseParams.airplaneCabin,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(noiseControllerProvider);
    final controller = ref.read(noiseControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noise'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: _presets.entries.map((entry) {
                  final isSelected = state.selectedPresetName == entry.key;
                  return ChoiceChip(
                    label: Text(entry.key),
                    selected: isSelected,
                    onSelected: (_) {
                      controller.selectPreset(entry.key, entry.value);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 64),
              Material(
                color: state.isPlaying
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHigh,
                shape: const CircleBorder(),
                elevation: state.isPlaying ? 8 : 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => controller.togglePlay(),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Icon(
                      state.isPlaying
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                      size: 64,
                      color: state.isPlaying
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                state.isPlaying ? 'Playing ${state.selectedPresetName}' : 'Stopped',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
