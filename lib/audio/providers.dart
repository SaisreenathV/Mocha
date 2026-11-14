import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/audio_engine.dart';
import 'soloud_audio_engine.dart';

final audioEngineProvider = Provider<AudioEngine>((ref) {
  final engine = SoLoudAudioEngine();
  ref.onDispose(() {
    engine.dispose();
  });
  return engine;
});
