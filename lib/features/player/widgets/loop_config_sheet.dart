import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../audio/loop_controller.dart';
import '../../../data/database.dart';
import '../../../domain/loop_config.dart';
import '../player_controller.dart';

class LoopConfigSheet extends ConsumerStatefulWidget {
  final Track track;

  const LoopConfigSheet({super.key, required this.track});

  @override
  ConsumerState<LoopConfigSheet> createState() => _LoopConfigSheetState();
}

class _LoopConfigSheetState extends ConsumerState<LoopConfigSheet> {
  late LoopMode _selectedMode;
  int _count = 3;
  int _durationMinutes = 30;
  double _startMs = 0.0;
  double _endMs = 1000.0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadInitialConfig();
      _initialized = true;
    }
  }

  Future<void> _loadInitialConfig() async {
    final loopController = ref.read(loopControllerProvider);
    final config = await loopController.getLoopConfig(widget.track.id, isSound: widget.track.isSound);
    final totalMs = (widget.track.durationMs ?? 10000).toDouble();

    setState(() {
      _selectedMode = config.mode;
      _count = config.count ?? 3;
      _durationMinutes = config.durationMs != null ? (config.durationMs! ~/ 60000) : 30;
      _startMs = (config.abStartMs?.toDouble() ?? 0.0).clamp(0.0, totalMs - 100);
      _endMs = (config.abEndMs?.toDouble() ?? totalMs).clamp(_startMs + 100, totalMs);
    });
  }

  String _formatTime(double ms) {
    final duration = Duration(milliseconds: ms.toInt());
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _apply() async {
    final loopController = ref.read(loopControllerProvider);
    final newConfig = LoopConfig(
      itemId: widget.track.id,
      mode: _selectedMode,
      count: _selectedMode == LoopMode.count ? _count : null,
      durationMs: _selectedMode == LoopMode.duration ? _durationMinutes * 60000 : null,
      abStartMs: _selectedMode == LoopMode.ab ? _startMs.toInt() : null,
      abEndMs: _selectedMode == LoopMode.ab ? _endMs.toInt() : null,
    );

    await loopController.applyConfig(newConfig);
    ref.read(activeLoopModeProvider.notifier).state = _selectedMode;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerState = ref.watch(playerControllerProvider);
    final totalMs = (widget.track.durationMs ?? playerState.duration.inMilliseconds).toDouble();
    final safeTotalMs = totalMs > 0 ? totalMs : 1000.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Loop Settings', style: theme.textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mode Selector
            Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.center,
              children: LoopMode.values.map((mode) {
                final isSelected = _selectedMode == mode;
                return ChoiceChip(
                  label: Text(mode.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedMode = mode),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Mode-specific configuration view
            if (_selectedMode == LoopMode.count) ...[
              Text('Loop passes: $_count', style: theme.textTheme.bodyMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [2, 3, 5, 10, 20].map((c) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ActionChip(
                      label: Text('${c}x'),
                      onPressed: () => setState(() => _count = c),
                    ),
                  );
                }).toList(),
              ),
            ] else if (_selectedMode == LoopMode.duration) ...[
              Text('Sleep timer: $_durationMinutes min', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                alignment: WrapAlignment.center,
                children: [15, 30, 45, 60, 120, 480].map((mins) {
                  return ActionChip(
                    label: Text(mins >= 60 ? '${mins ~/ 60}h' : '${mins}m'),
                    onPressed: () => setState(() => _durationMinutes = mins),
                  );
                }).toList(),
              ),
            ] else if (_selectedMode == LoopMode.ab) ...[
              // Help text: honest disclaimer
              Text(
                'Note: A-B looping is near-gapless, NOT sample-accurate.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              RangeSlider(
                values: RangeValues(_startMs.clamp(0.0, safeTotalMs), _endMs.clamp(0.0, safeTotalMs)),
                min: 0.0,
                max: safeTotalMs,
                onChanged: (values) {
                  setState(() {
                    _startMs = values.start;
                    _endMs = values.end;
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('A: ${_formatTime(_startMs)}', style: theme.textTheme.labelMedium),
                  Text('B: ${_formatTime(_endMs)}', style: theme.textTheme.labelMedium),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.bookmark_border),
                    label: const Text('Set A (Now)'),
                    onPressed: () {
                      final current = playerState.position.inMilliseconds.toDouble();
                      if (current < _endMs) setState(() => _startMs = current);
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.bookmark),
                    label: const Text('Set B (Now)'),
                    onPressed: () {
                      final current = playerState.position.inMilliseconds.toDouble();
                      if (current > _startMs) setState(() => _endMs = current);
                    },
                  ),
                ],
              ),
            ] else ...[
              Text(
                _selectedMode == LoopMode.forever ? 'Repeats indefinitely.' : 'Stops at end of track.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _apply,
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
