import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocha/audio/dsp/brown_noise_synthesizer.dart';
import 'package:mocha/domain/noise_params.dart';

double _goertzelEnergy(List<double> signal, double targetFreq, int sampleRate) {
  double totalEnergy = 0.0;
  const offsets = [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0];
  for (final offset in offsets) {
    final freq = targetFreq + offset;
    final omega = 2.0 * math.pi * freq / sampleRate;
    final coeff = 2.0 * math.cos(omega);
    double s1 = 0.0;
    double s2 = 0.0;
    for (int i = 0; i < signal.length; i++) {
      final s0 = signal[i] + coeff * s1 - s2;
      s2 = s1;
      s1 = s0;
    }
    totalEnergy += (s1 * s1 + s2 * s2 - coeff * s1 * s2);
  }
  return totalEnergy / offsets.length;
}

void main() {
  group('BrownNoiseSynthesizer', () {
    test('all samples are finite and within [-1.0, 1.0]', () {
      final synth = BrownNoiseSynthesizer(seedL: 100, seedR: 200);
      final samples = synth.renderStereo(
        NoiseParams.classicBrown,
        seconds: 4.0,
        sampleRate: 44100,
      );

      for (int i = 0; i < samples.length; i++) {
        final s = samples[i];
        expect(s.isFinite, isTrue, reason: 'Sample at $i is not finite');
        expect(s >= -1.0 && s <= 1.0, isTrue, reason: 'Sample $s out of bounds');
      }
    });

    test('L == R when stereoWidth is 0.0', () {
      final synth = BrownNoiseSynthesizer(seedL: 101, seedR: 202);
      const monoParams = NoiseParams(
        depth: 30.0,
        cutoffHz: 800.0,
        warmthDb: 0.0,
        stereoWidth: 0.0,
      );
      final samples = synth.renderStereo(
        monoParams,
        seconds: 3.0,
        sampleRate: 44100,
      );

      final totalFrames = samples.length ~/ 2;
      for (int i = 0; i < totalFrames; i++) {
        final left = samples[i * 2];
        final right = samples[i * 2 + 1];
        expect(left, equals(right), reason: 'Channel mismatch at frame $i');
      }
    });

    test('small step at loop seam', () {
      final synth = BrownNoiseSynthesizer(seedL: 303, seedR: 404);
      final samples = synth.renderStereo(
        NoiseParams.classicBrown,
        seconds: 5.0,
        sampleRate: 44100,
      );

      final totalFrames = samples.length ~/ 2;
      final headL = samples[0];
      final headR = samples[1];
      final tailL = samples[(totalFrames - 1) * 2];
      final tailR = samples[(totalFrames - 1) * 2 + 1];

      final stepL = (headL - tailL).abs();
      final stepR = (headR - tailR).abs();

      expect(stepL, lessThan(0.15));
      expect(stepR, lessThan(0.15));
    });

    test('Goertzel band-energy shows roughly -6 dB/octave above corner', () {
      final synth = BrownNoiseSynthesizer(seedL: 42, seedR: 1337);
      const testParams = NoiseParams(
        depth: 20.0,
        cutoffHz: 4000.0,
        warmthDb: 0.0,
        stereoWidth: 0.4,
      );
      final samples = synth.renderStereo(
        testParams,
        seconds: 10.0,
        sampleRate: 44100,
      );

      final leftChannel = <double>[];
      for (int i = 0; i < samples.length; i += 2) {
        leftChannel.add(samples[i]);
      }

      final freqs = [100.0, 200.0, 400.0, 800.0, 1600.0];
      final dbs = freqs.map((f) {
        final energy = _goertzelEnergy(leftChannel, f, 44100);
        return 10.0 * (math.log(energy) / math.ln10);
      }).toList();

      for (int i = 0; i < dbs.length - 1; i++) {
        final deltaDb = dbs[i + 1] - dbs[i];
        expect(
          deltaDb,
          inInclusiveRange(-8.5, -3.5),
          reason: 'Slope from ${freqs[i]}Hz to ${freqs[i + 1]}Hz was $deltaDb dB',
        );
      }
    });
  });
}
