import 'dart:convert';
import 'noise_params.dart';

class LayeredSoundConfig {
  final String trackId;
  final String filePath;
  final String title;
  final double volume;
  final String loopMode; // 'off', 'forever', 'count', 'duration', 'ab'
  final int? count;
  final int? durationMs;
  final int? abStartMs;
  final int? abEndMs;

  const LayeredSoundConfig({
    required this.trackId,
    required this.filePath,
    required this.title,
    this.volume = 0.8,
    this.loopMode = 'forever',
    this.count,
    this.durationMs,
    this.abStartMs,
    this.abEndMs,
  });

  Map<String, dynamic> toMap() => {
        'trackId': trackId,
        'filePath': filePath,
        'title': title,
        'volume': volume,
        'loopMode': loopMode,
        'count': count,
        'durationMs': durationMs,
        'abStartMs': abStartMs,
        'abEndMs': abEndMs,
      };

  factory LayeredSoundConfig.fromMap(Map<String, dynamic> map) {
    return LayeredSoundConfig(
      trackId: map['trackId'] as String,
      filePath: map['filePath'] as String,
      title: map['title'] as String? ?? 'Sound',
      volume: (map['volume'] as num?)?.toDouble() ?? 0.8,
      loopMode: map['loopMode'] as String? ?? 'forever',
      count: map['count'] as int?,
      durationMs: map['durationMs'] as int?,
      abStartMs: map['abStartMs'] as int?,
      abEndMs: map['abEndMs'] as int?,
    );
  }
}

class SavedMixModel {
  final String id;
  final String name;
  final NoiseParams noiseParams;
  final double noiseVolume;
  final List<LayeredSoundConfig> sounds;

  const SavedMixModel({
    required this.id,
    required this.name,
    required this.noiseParams,
    this.noiseVolume = 0.8,
    this.sounds = const [],
  });

  String get noiseParamsJson => jsonEncode({
        'depth': noiseParams.depth,
        'cutoffHz': noiseParams.cutoffHz,
        'warmthDb': noiseParams.warmthDb,
        'stereoWidth': noiseParams.stereoWidth,
        'volume': noiseParams.volume,
      });

  static NoiseParams parseNoiseParams(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return NoiseParams(
        depth: (map['depth'] as num?)?.toDouble() ?? 30.0,
        cutoffHz: (map['cutoffHz'] as num?)?.toDouble() ?? 800.0,
        warmthDb: (map['warmthDb'] as num?)?.toDouble() ?? 0.0,
        stereoWidth: (map['stereoWidth'] as num?)?.toDouble() ?? 0.4,
        volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      );
    } catch (_) {
      return NoiseParams.classicBrown;
    }
  }

  String get soundsJson =>
      jsonEncode(sounds.take(3).map((s) => s.toMap()).toList());

  static List<LayeredSoundConfig> parseSounds(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((item) =>
              LayeredSoundConfig.fromMap(item as Map<String, dynamic>))
          .take(3)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
