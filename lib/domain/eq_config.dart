import 'dart:convert';

class EqBand {
  final int index;
  final String label;
  final double gainDb; // -12.0 dB to +12.0 dB

  const EqBand({
    required this.index,
    required this.label,
    this.gainDb = 0.0,
  });

  EqBand copyWith({double? gainDb}) {
    return EqBand(
      index: index,
      label: label,
      gainDb: gainDb ?? this.gainDb,
    );
  }

  Map<String, dynamic> toMap() => {
        'index': index,
        'label': label,
        'gainDb': gainDb,
      };

  factory EqBand.fromMap(Map<String, dynamic> map) {
    return EqBand(
      index: map['index'] as int,
      label: map['label'] as String,
      gainDb: (map['gainDb'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EqConfig {
  final bool enabled;
  final String presetName;
  final List<EqBand> bands;
  final double crossfadeSeconds; // 0.0 to 12.0 seconds

  static const List<String> bandLabels = [
    '60 Hz',
    '150 Hz',
    '400 Hz',
    '1 kHz',
    '2.4 kHz',
    '6 kHz',
    '12 kHz',
    '15 kHz',
  ];

  static const Map<String, List<double>> presets = {
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Bass boost': [5.0, 4.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Vocal': [-2.0, -1.0, 1.0, 3.5, 3.0, 1.5, 0.0, -1.0],
    'Night': [-4.0, -2.5, -1.0, 1.0, 1.0, -1.0, -3.0, -5.0],
  };

  const EqConfig({
    this.enabled = true,
    this.presetName = 'Flat',
    required this.bands,
    this.crossfadeSeconds = 3.0,
  });

  factory EqConfig.defaultConfig() {
    return EqConfig(
      enabled: true,
      presetName: 'Flat',
      bands: List.generate(
        bandLabels.length,
        (i) => EqBand(index: i, label: bandLabels[i], gainDb: 0.0),
      ),
      crossfadeSeconds: 3.0,
    );
  }

  EqConfig copyWith({
    bool? enabled,
    String? presetName,
    List<EqBand>? bands,
    double? crossfadeSeconds,
  }) {
    return EqConfig(
      enabled: enabled ?? this.enabled,
      presetName: presetName ?? this.presetName,
      bands: bands ?? this.bands,
      crossfadeSeconds: (crossfadeSeconds ?? this.crossfadeSeconds).clamp(0.0, 12.0),
    );
  }

  String get bandsJson => jsonEncode(bands.map((b) => b.toMap()).toList());

  static List<EqBand> parseBands(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((m) => EqBand.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return List.generate(
        bandLabels.length,
        (i) => EqBand(index: i, label: bandLabels[i], gainDb: 0.0),
      );
    }
  }
}
