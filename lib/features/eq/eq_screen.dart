import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/eq_config.dart';
import 'eq_controller.dart';

class EqScreen extends ConsumerWidget {
  const EqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = ref.watch(eqControllerProvider);
    final eqCtrl = ref.read(eqControllerProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer & Crossfade'),
        actions: [
          Row(
            children: [
              Text(eq.enabled ? 'ON' : 'OFF',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Switch(
                value: eq.enabled,
                onChanged: (_) => eqCtrl.toggleEnabled(),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Global bus note
          Card(
            color: cs.surfaceContainerHighest,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Global bus equalizer: affects generated brown noise and audio files simultaneously.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Presets
          Text('Presets', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: EqConfig.presets.keys.map((name) {
              final isSelected = eq.presetName == name;
              return ChoiceChip(
                label: Text(name),
                selected: isSelected,
                onSelected: (_) => eqCtrl.selectPreset(name),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Real 8-band EQ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('8-Band Equalizer', style: Theme.of(context).textTheme.titleMedium),
              Text(
                '±12 dB range',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bands (vertical sliders container)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: eq.bands.map((band) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Text(
                          band.label,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: band.gainDb,
                          min: -12.0,
                          max: 12.0,
                          divisions: 48,
                          onChanged: eq.enabled
                              ? (v) => eqCtrl.setBandGain(band.index, v)
                              : null,
                        ),
                      ),
                      SizedBox(
                        width: 58,
                        child: Text(
                          '${band.gainDb >= 0 ? '+' : ''}${band.gainDb.toStringAsFixed(1)} dB',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: band.gainDb != 0.0 ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Crossfade Section
          Text('Track Crossfade', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Blends adjacent queue tracks smoothly. Does not apply while looping.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.compare_arrows_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: eq.crossfadeSeconds,
                  min: 0.0,
                  max: 12.0,
                  divisions: 24,
                  onChanged: (v) => eqCtrl.setCrossfadeSeconds(v),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  eq.crossfadeSeconds == 0.0
                      ? 'Off'
                      : '${eq.crossfadeSeconds.toStringAsFixed(1)} s',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
