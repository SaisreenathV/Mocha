import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/database.dart';
import '../../domain/mix_model.dart';
import '../../domain/noise_params.dart';
import 'mix_controller.dart';

class MixesScreen extends ConsumerWidget {
  const MixesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mixesAsync = ref.watch(mixesStreamProvider);
    final mixState = ref.watch(mixControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mixes')),
      body: mixesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (mixes) {
          if (mixes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No mixes yet — tap + to create one.'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: mixes.length,
            itemBuilder: (context, i) {
              final m = mixes[i];
              final isActive = mixState.currentMix?.id == m.id;
              return _MixTile(
                mixData: m,
                isActive: isActive,
                isPlaying: isActive && mixState.isPlaying,
                noiseVolume: isActive ? mixState.noiseVolume : m.noiseVolume,
                trackVolume: isActive ? mixState.trackVolume : m.trackVolume,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProviderScope(parent: ref.container, child: const _CreateMixSheet()),
    );
  }
}

class _MixTile extends ConsumerStatefulWidget {
  final MixData mixData;
  final bool isActive;
  final bool isPlaying;
  final double noiseVolume;
  final double trackVolume;

  const _MixTile({
    required this.mixData,
    required this.isActive,
    required this.isPlaying,
    required this.noiseVolume,
    required this.trackVolume,
  });

  @override
  ConsumerState<_MixTile> createState() => _MixTileState();
}

class _MixTileState extends ConsumerState<_MixTile> {
  late double _noiseVol;
  late double _trackVol;

  @override
  void initState() {
    super.initState();
    _noiseVol = widget.noiseVolume;
    _trackVol = widget.trackVolume;
  }

  @override
  void didUpdateWidget(_MixTile old) {
    super.didUpdateWidget(old);
    if (!widget.isActive) {
      _noiseVol = widget.noiseVolume;
      _trackVol = widget.trackVolume;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(mixControllerProvider.notifier);
    final m = widget.mixData;
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(m.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: cs.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: cs.onError),
      ),
      onDismissed: (_) => ctrl.deleteMix(m.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: widget.isActive ? cs.primaryContainer : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Chip(
                          label: Text(m.noisePreset),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(widget.isPlaying ? Icons.pause_circle : Icons.play_circle),
                    iconSize: 36,
                    onPressed: () {
                      if (widget.isPlaying) {
                        ctrl.stopMix();
                      } else {
                        ctrl.playMix(SoundscapeMix(
                          id: m.id,
                          name: m.name,
                          noisePreset: m.noisePreset,
                          noiseVolume: m.noiseVolume,
                          trackId: m.trackId,
                          trackVolume: m.trackVolume,
                        ));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.noise_aware, size: 16),
                  const SizedBox(width: 4),
                  const Text('Noise', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: _noiseVol,
                      min: 0,
                      max: 1,
                      onChanged: (v) {
                        setState(() => _noiseVol = v);
                        if (widget.isActive) ctrl.setNoiseVolume(v);
                      },
                    ),
                  ),
                ],
              ),
              if (m.trackId != null)
                Row(
                  children: [
                    const Icon(Icons.music_note, size: 16),
                    const SizedBox(width: 4),
                    const Text('Track', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _trackVol,
                        min: 0,
                        max: 1,
                        onChanged: (v) {
                          setState(() => _trackVol = v);
                          if (widget.isActive) ctrl.setTrackVolume(v);
                        },
                      ),
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

// ---------------------------------------------------------------------------
// Create / Edit sheet
// ---------------------------------------------------------------------------

class _CreateMixSheet extends ConsumerStatefulWidget {
  const _CreateMixSheet();

  @override
  ConsumerState<_CreateMixSheet> createState() => _CreateMixSheetState();
}

class _CreateMixSheetState extends ConsumerState<_CreateMixSheet> {
  final _nameCtrl = TextEditingController();
  String _preset = NoiseParams.presets.first.name;
  double _noiseVol = 0.8;
  double _trackVol = 0.8;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.read(mixControllerProvider.notifier);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Mix', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          Text('Noise preset', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: NoiseParams.presets.map((p) {
              return ChoiceChip(
                label: Text(p.name),
                selected: _preset == p.name,
                onSelected: (_) => setState(() => _preset = p.name),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Noise vol'),
            Expanded(child: Slider(value: _noiseVol, onChanged: (v) => setState(() => _noiseVol = v))),
          ]),
          Row(children: [
            const Text('Track vol'),
            Expanded(child: Slider(value: _trackVol, onChanged: (v) => setState(() => _trackVol = v))),
          ]),
          // TODO: track picker — open library bottom sheet to select a track
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) return;
                final mix = SoundscapeMix(
                  id: const Uuid().v4(),
                  name: name,
                  noisePreset: _preset,
                  noiseVolume: _noiseVol,
                  trackVolume: _trackVol,
                );
                await ctrl.saveMix(mix);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save Mix'),
            ),
          ),
        ],
      ),
    );
  }
}
