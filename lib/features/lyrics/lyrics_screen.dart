import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../domain/lrc_parser.dart';
import '../player/player_controller.dart';

class LyricsScreen extends ConsumerStatefulWidget {
  final Track track;

  const LyricsScreen({super.key, required this.track});

  static Future<void> open(BuildContext context, Track track) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LyricsScreen(track: track),
      ),
    );
  }

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  LrcDocument? _document;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    final doc = await LrcParser.findSidecar(widget.track.filePath);
    if (mounted) {
      setState(() {
        _document = doc;
        _isLoading = false;
      });
    }
  }

  void _scrollToActive(int index) {
    if (index == _lastActiveIndex || !_scrollController.hasClients) return;
    _lastActiveIndex = index;

    // Approximate line height ~52px
    final targetOffset = (index * 56.0) - 150.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerControllerProvider);
    final playerCtrl = ref.read(playerControllerProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    final doc = _document;
    final activeIndex = doc?.getActiveIndex(playerState.position) ?? -1;

    if (activeIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActive(activeIndex);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.track.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (widget.track.artist != null)
              Text(
                widget.track.artist!,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (doc == null || doc.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.subtitles_off_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No synced lyrics found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Place a .lrc file next to "${widget.track.title}" to view synced lyrics here.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  itemCount: doc.lines.length,
                  itemBuilder: (context, i) {
                    final line = doc.lines[i];
                    final isActive = i == activeIndex;

                    return InkWell(
                      onTap: () => playerCtrl.seek(line.timestamp),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isActive ? 22 : 16,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.45),
                            height: 1.4,
                          ),
                          child: Text(
                            line.text.isEmpty ? '♪' : line.text,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
