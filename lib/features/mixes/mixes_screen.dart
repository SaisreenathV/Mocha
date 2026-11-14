import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../data/providers.dart';
import '../../domain/saved_mix.dart';
import '../player/widgets/timer_sheet.dart';
import 'mix_controller.dart';

class MixesScreen extends ConsumerWidget {
  const MixesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedMixesAsync = ref.watch(savedMixesStreamProvider);
    final mixState = ref.watch(mixControllerProvider);
    final mixCtrl = ref.read(mixControllerProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soundscape Mixes'),
        actions: [
          IconButton(
            tooltip: 'Timers',
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => TimerSheet.show(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Active Mix Panel
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.all(12),
              color: cs.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.graphic_eq, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          mixState.activeSavedMix?.name ?? 'Active Soundscape',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton.filledTonal(
                          icon: Icon(mixState.isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: () {
                            if (mixState.isPlaying) {
                              mixCtrl.stopMix();
                            } else {
                              mixCtrl.playMix();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Noise voice volume
                    Row(
                      children: [
                        const Icon(Icons.grain, size: 18),
                        const SizedBox(width: 8),
                        const Text('Brown Noise', style: TextStyle(fontWeight: FontWeight.w600)),
                        Expanded(
                          child: Slider(
                            value: mixState.noiseVolume,
                            onChanged: (v) => mixCtrl.setNoiseVolume(v),
                          ),
                        ),
                      ],
                    ),

                    // Up to 3 Layered Sounds
                    const SizedBox(height: 8),
                    Text(
                      'Layered Sounds (${mixState.layeredSounds.length}/3)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    if (mixState.layeredSounds.isEmpty)
                      const Text(
                        'No layered sounds. Add up to 3 sounds to loop alongside noise.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      ...List.generate(mixState.layeredSounds.length, (i) {
                        final sound = mixState.layeredSounds[i];
                        return Row(
                          children: [
                            const Icon(Icons.music_note, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Text(
                                sound.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Slider(
                                value: sound.volume,
                                onChanged: (v) => mixCtrl.setLayerVolume(i, v),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => mixCtrl.removeSound(i),
                            ),
                          ],
                        );
                      }),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (mixState.layeredSounds.length < 3)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Sound'),
                            onPressed: () => _showAddSoundPicker(context, ref),
                          ),
                        const Spacer(),
                        FilledButton.icon(
                          icon: const Icon(Icons.save_outlined, size: 16),
                          label: const Text('Save Mix'),
                          onPressed: () => _showSaveMixDialog(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Saved Mixes Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Saved Mixes (1-Tap Restore)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          // Saved Mixes List
          savedMixesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (mixes) {
              if (mixes.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No saved mixes yet. Save your current soundscape above!'),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final m = mixes[i];
                    final sounds = SavedMixModel.parseSounds(m.soundsJson);
                    final isCurrent = mixState.activeSavedMix?.id == m.id;

                    return Dismissible(
                      key: ValueKey(m.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: cs.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: cs.onError),
                      ),
                      onDismissed: (_) => mixCtrl.deleteSavedMix(m.id),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrent ? cs.primary : cs.surfaceContainerHighest,
                          foregroundColor: isCurrent ? cs.onPrimary : cs.onSurface,
                          child: Icon(isCurrent && mixState.isPlaying
                              ? Icons.graphic_eq
                              : Icons.layers),
                        ),
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${sounds.length} layered sound${sounds.length == 1 ? '' : 's'} • Noise vol: ${(m.noiseVolume * 100).round()}%',
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () => mixCtrl.restoreMix(m),
                          child: Text(isCurrent && mixState.isPlaying ? 'Active' : 'Restore'),
                        ),
                        onTap: () => mixCtrl.restoreMix(m),
                      ),
                    );
                  },
                  childCount: mixes.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddSoundPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final tracksAsync = ref.watch(tracksStreamProvider(''));
            return tracksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (tracks) {
                if (tracks.isEmpty) {
                  return const Center(child: Text('No audio files in library. Import sounds first!'));
                }
                return ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, i) {
                    final t = tracks[i];
                    return ListTile(
                      leading: const Icon(Icons.audiotrack),
                      title: Text(t.title),
                      subtitle: Text(t.artist ?? 'Local Sound'),
                      onTap: () {
                        ref.read(mixControllerProvider.notifier).addSound(t);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSaveMixDialog(BuildContext context, WidgetRef ref) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Mix'),
        content: TextField(
          controller: textCtrl,
          decoration: const InputDecoration(
            labelText: 'Mix Name',
            hintText: 'e.g. Deep Forest Rain',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = textCtrl.text.trim();
              if (name.isNotEmpty) {
                ref.read(mixControllerProvider.notifier).saveCurrentMix(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
