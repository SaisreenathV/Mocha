import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'audio/soloud_audio_engine.dart';
import 'platform/mocha_audio_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final engine = SoLoudAudioEngine();
  globalAudioHandler = await AudioService.init(
    builder: () => MochaAudioHandler(engine),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mocha.audio.playback',
      androidNotificationChannelName: 'Mocha Noise Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    const ProviderScope(
      child: MochaApp(),
    ),
  );
}
