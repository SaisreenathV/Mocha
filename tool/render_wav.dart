import 'dart:io';
import '../lib/audio/dsp/brown_noise_synthesizer.dart';
import '../lib/domain/noise_params.dart';

void main() async {
  final synth = BrownNoiseSynthesizer();
  final samples = synth.renderStereo(
    NoiseParams.classicBrown,
    seconds: 30.0,
    sampleRate: 44100,
  );

  final wavBytes = synth.toWav16(samples, sampleRate: 44100);

  final outDir = Directory('out');
  if (!await outDir.exists()) {
    await outDir.create(recursive: true);
  }

  final outFile = File('out/classic_brown.wav');
  await outFile.writeAsBytes(wavBytes);
}
