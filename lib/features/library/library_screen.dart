import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../data/providers.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isImporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleImport() async {
    final importer = ref.read(importerProvider);
    setState(() => _isImporting = true);

    if (Platform.isLinux && mounted) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.audio_file_outlined),
                title: const Text('Pick Audio Files'),
                onTap: () => Navigator.pop(ctx, 'files'),
              ),
              ListTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: const Text('Scan Entire Folder'),
                onTap: () => Navigator.pop(ctx, 'folder'),
              ),
            ],
          ),
        ),
      );

      int count = 0;
      if (choice == 'folder') {
        count = await importer.pickAndImportDirectory();
      } else if (choice == 'files') {
        count = await importer.pickAndImportFiles();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count tracks')),
        );
      }
    } else {
      final count = await importer.pickAndImportFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $count tracks')),
        );
      }
    }

    if (mounted) setState(() => _isImporting = false);
  }

  String _formatDuration(int? ms) {
    if (ms == null || ms <= 0) return '--:--';
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(tracksStreamProvider(_query));
    final db = ref.read(databaseProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded),
            tooltip: 'Import music',
            onPressed: _isImporting ? null : _handleImport,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search title, artist, or album...',
              leading: const Icon(Icons.search),
              trailing: _query.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                    ]
                  : null,
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          Expanded(
            child: tracksAsync.when(
              data: (tracks) {
                if (tracks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_music_outlined,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _query.isEmpty ? 'Library is empty' : 'No matching tracks',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.add),
                          label: const Text('Import Audio'),
                          onPressed: _handleImport,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.surfaceContainerHigh,
                        child: Icon(
                          track.isSound
                              ? Icons.graphic_eq_rounded
                              : Icons.music_note_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          if (track.artist != null) track.artist,
                          if (track.album != null) track.album,
                          _formatDuration(track.durationMs),
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: FilterChip(
                        label: Text(track.isSound ? 'Sound' : 'Song'),
                        selected: track.isSound,
                        onSelected: (_) => db.toggleIsSound(track.id, track.isSound),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
