class SoundscapeMix {
  final String id;
  final String name;
  final String noisePreset;
  final double noiseVolume;
  final String? trackId;
  final double trackVolume;

  const SoundscapeMix({
    required this.id,
    required this.name,
    this.noisePreset = 'Classic Brown',
    this.noiseVolume = 0.8,
    this.trackId,
    this.trackVolume = 0.8,
  });

  SoundscapeMix copyWith({
    String? id,
    String? name,
    String? noisePreset,
    double? noiseVolume,
    String? trackId,
    double? trackVolume,
  }) {
    return SoundscapeMix(
      id: id ?? this.id,
      name: name ?? this.name,
      noisePreset: noisePreset ?? this.noisePreset,
      noiseVolume: noiseVolume ?? this.noiseVolume,
      trackId: trackId ?? this.trackId,
      trackVolume: trackVolume ?? this.trackVolume,
    );
  }
}
