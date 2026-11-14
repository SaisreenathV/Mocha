enum LoopMode {
  off,
  forever,
  count,
  duration,
  ab,
}

class LoopConfig {
  final String itemId;
  final LoopMode mode;
  final int? count;
  final int? durationMs;
  final int? abStartMs;
  final int? abEndMs;

  const LoopConfig({
    required this.itemId,
    required this.mode,
    this.count,
    this.durationMs,
    this.abStartMs,
    this.abEndMs,
  });

  /// Sounds default to forever, songs default to off, brown noise is always forever.
  static LoopMode defaultModeFor({required bool isSound, bool isBrownNoise = false}) {
    if (isBrownNoise || isSound) {
      return LoopMode.forever;
    }
    return LoopMode.off;
  }

  LoopConfig copyWith({
    String? itemId,
    LoopMode? mode,
    int? count,
    int? durationMs,
    int? abStartMs,
    int? abEndMs,
  }) {
    return LoopConfig(
      itemId: itemId ?? this.itemId,
      mode: mode ?? this.mode,
      count: count ?? this.count,
      durationMs: durationMs ?? this.durationMs,
      abStartMs: abStartMs ?? this.abStartMs,
      abEndMs: abEndMs ?? this.abEndMs,
    );
  }
}
