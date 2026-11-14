class NoiseParams {
  /// Depth represents the leaky integrator corner frequency in Hz.
  final double depth;

  /// Low-pass filter cutoff frequency in Hz.
  final double cutoffHz;

  /// Low-shelf boost/cut at 180 Hz in dB.
  final double warmthDb;

  /// Stereo width factor from 0.0 (mono) to 1.0 (full stereo).
  final double stereoWidth;

  /// Output volume scalar (default 1.0).
  final double volume;

  const NoiseParams({
    required this.depth,
    required this.cutoffHz,
    required this.warmthDb,
    required this.stereoWidth,
    this.volume = 1.0,
  });

  NoiseParams copyWith({
    double? depth,
    double? cutoffHz,
    double? warmthDb,
    double? stereoWidth,
    double? volume,
  }) {
    return NoiseParams(
      depth: depth ?? this.depth,
      cutoffHz: cutoffHz ?? this.cutoffHz,
      warmthDb: warmthDb ?? this.warmthDb,
      stereoWidth: stereoWidth ?? this.stereoWidth,
      volume: volume ?? this.volume,
    );
  }

  static const NoiseParams classicBrown = NoiseParams(
    depth: 30.0,
    cutoffHz: 800.0,
    warmthDb: 0.0,
    stereoWidth: 0.4,
    volume: 1.0,
  );

  static const NoiseParams deepRumble = NoiseParams(
    depth: 20.0,
    cutoffHz: 350.0,
    warmthDb: 4.0,
    stereoWidth: 0.2,
    volume: 1.0,
  );

  static const NoiseParams softBrown = NoiseParams(
    depth: 45.0,
    cutoffHz: 650.0,
    warmthDb: -2.0,
    stereoWidth: 0.3,
    volume: 1.0,
  );

  static const NoiseParams focus = NoiseParams(
    depth: 60.0,
    cutoffHz: 1200.0,
    warmthDb: -1.0,
    stereoWidth: 0.2,
    volume: 1.0,
  );

  static const NoiseParams deepSleep = NoiseParams(
    depth: 22.0,
    cutoffHz: 400.0,
    warmthDb: 3.5,
    stereoWidth: 0.1,
    volume: 1.0,
  );

  static const NoiseParams airplaneCabin = NoiseParams(
    depth: 40.0,
    cutoffHz: 500.0,
    warmthDb: 2.0,
    stereoWidth: 0.5,
    volume: 1.0,
  );
}
