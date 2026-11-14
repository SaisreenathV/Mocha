import 'dart:math' as math;
import 'dart:typed_data';
import '../../domain/noise_params.dart';

class _BiquadFilter {
  double b0 = 1.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0;
  double z1 = 0.0, z2 = 0.0;

  void setLowPass(double cutoffHz, int sampleRate, [double q = 0.70710678]) {
    final omega = 2.0 * math.pi * (cutoffHz / sampleRate).clamp(0.0001, 0.499);
    final alpha = math.sin(omega) / (2.0 * q);
    final cosw = math.cos(omega);

    final a0 = 1.0 + alpha;
    b0 = ((1.0 - cosw) * 0.5) / a0;
    b1 = (1.0 - cosw) / a0;
    b2 = ((1.0 - cosw) * 0.5) / a0;
    a1 = (-2.0 * cosw) / a0;
    a2 = (1.0 - alpha) / a0;
  }

  void setLowShelf180Hz(double gainDb, int sampleRate) {
    if (gainDb.abs() < 1e-4) {
      b0 = 1.0; b1 = 0.0; b2 = 0.0; a1 = 0.0; a2 = 0.0;
      return;
    }
    final a = math.pow(10.0, gainDb / 40.0).toDouble();
    final omega = 2.0 * math.pi * (180.0 / sampleRate).clamp(0.0001, 0.499);
    final sinw = math.sin(omega);
    final cosw = math.cos(omega);
    final alpha = (sinw * 0.5) * math.sqrt(2.0); // S = 1.0
    final twoSqrtAAlpha = 2.0 * math.sqrt(a) * alpha;

    final a0 = (a + 1.0) + (a - 1.0) * cosw + twoSqrtAAlpha;
    b0 = (a * ((a + 1.0) - (a - 1.0) * cosw + twoSqrtAAlpha)) / a0;
    b1 = (2.0 * a * ((a - 1.0) - (a + 1.0) * cosw)) / a0;
    b2 = (a * ((a + 1.0) - (a - 1.0) * cosw - twoSqrtAAlpha)) / a0;
    a1 = (-2.0 * ((a - 1.0) + (a + 1.0) * cosw)) / a0;
    a2 = ((a + 1.0) + (a - 1.0) * cosw - twoSqrtAAlpha) / a0;
  }

  double process(double input) {
    final output = b0 * input + z1;
    z1 = b1 * input - a1 * output + z2;
    z2 = b2 * input - a2 * output;
    return output;
  }
}

class BrownNoiseSynthesizer {
  final math.Random _randomL;
  final math.Random _randomR;

  BrownNoiseSynthesizer({int? seedL, int? seedR})
      : _randomL = math.Random(seedL ?? 42),
        _randomR = math.Random(seedR ?? 1337);

  Float32List renderStereo(
    NoiseParams params, {
    double seconds = 10.0,
    int sampleRate = 44100,
  }) {
    final nFrames = (seconds * sampleRate).round();
    const crossfadeSec = 2.0;
    final xFrames = (crossfadeSec * sampleRate).round();
    final totalFrames = nFrames + xFrames;

    final rawL = Float64List(totalFrames);
    final rawR = Float64List(totalFrames);

    // Leaky integrator setup (depth = corner frequency in Hz)
    final wc = 2.0 * math.pi * (params.depth / sampleRate).clamp(0.0001, 0.499);
    final alpha = math.exp(-wc);
    final oneMinusAlpha = 1.0 - alpha;

    // Filters per channel
    final lpfL = _BiquadFilter()..setLowPass(params.cutoffHz, sampleRate);
    final lpfR = _BiquadFilter()..setLowPass(params.cutoffHz, sampleRate);
    final shelfL = _BiquadFilter()..setLowShelf180Hz(params.warmthDb, sampleRate);
    final shelfR = _BiquadFilter()..setLowShelf180Hz(params.warmthDb, sampleRate);

    double integL = 0.0;
    double integR = 0.0;

    for (int i = 0; i < totalFrames; i++) {
      // 1. Decorrelated white noise
      final whiteL = _randomL.nextDouble() * 2.0 - 1.0;
      final whiteR = _randomR.nextDouble() * 2.0 - 1.0;

      // 2. Leaky integrator
      integL = alpha * integL + oneMinusAlpha * whiteL;
      integR = alpha * integR + oneMinusAlpha * whiteR;

      // 3. Low-pass biquad
      final filteredL = lpfL.process(integL);
      final filteredR = lpfR.process(integR);

      // 4. Low-shelf at 180 Hz
      final warmedL = shelfL.process(filteredL);
      final warmedR = shelfR.process(filteredR);

      // 5. Mid/Side stereo width
      final mid = (warmedL + warmedR) * 0.5;
      final side = (warmedL - warmedR) * 0.5 * params.stereoWidth;
      rawL[i] = mid + side;
      rawR[i] = mid - side;
    }

    // 6. Seamless loop: equal-power crossfade extra tail (X frames) into head
    final output = Float32List(nFrames * 2);
    for (int i = 0; i < xFrames; i++) {
      final t = i / xFrames;
      final theta = t * (math.pi * 0.5);
      final gainTail = math.cos(theta);
      final gainHead = math.sin(theta);

      final outL = gainHead * rawL[i] + gainTail * rawL[nFrames + i];
      final outR = gainHead * rawR[i] + gainTail * rawR[nFrames + i];
      output[i * 2] = outL;
      output[i * 2 + 1] = outR;
    }
    for (int i = xFrames; i < nFrames; i++) {
      output[i * 2] = rawL[i];
      output[i * 2 + 1] = rawR[i];
    }

    // 7. Normalise to about -18 dBFS RMS and soft-clip
    double sumSquares = 0.0;
    final totalSamples = output.length;
    for (int i = 0; i < totalSamples; i++) {
      sumSquares += output[i] * output[i];
    }
    final currentRms = math.sqrt(sumSquares / totalSamples);
    final targetRms = math.pow(10.0, -18.0 / 20.0).toDouble(); // ~0.12589
    final gain = (targetRms / (currentRms + 1e-9)) * params.volume;

    for (int i = 0; i < totalSamples; i++) {
      final scaled = output[i] * gain;
      // Soft-clip via tanh
      final e2x = math.exp((scaled * 2.0).clamp(-20.0, 20.0));
      final clipped = (e2x - 1.0) / (e2x + 1.0);
      output[i] = clipped.clamp(-1.0, 1.0);
    }

    return output;
  }

  Uint8List toWav16(Float32List interleavedStereo, {int sampleRate = 44100}) {
    final numSamples = interleavedStereo.length;
    final byteData = ByteData(44 + numSamples * 2);

    void writeString(int offset, String str) {
      for (int i = 0; i < str.length; i++) {
        byteData.setUint8(offset + i, str.codeUnitAt(i));
      }
    }

    final dataSize = numSamples * 2;
    writeString(0, 'RIFF');
    byteData.setUint32(4, 36 + dataSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little); // PCM subchunk size
    byteData.setUint16(20, 1, Endian.little);  // Format = 1 (PCM)
    byteData.setUint16(22, 2, Endian.little);  // 2 channels
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 4, Endian.little); // byte rate (sampleRate * 2 channels * 2 bytes)
    byteData.setUint16(32, 4, Endian.little);  // block align
    byteData.setUint16(34, 16, Endian.little); // bits per sample
    writeString(36, 'data');
    byteData.setUint32(40, dataSize, Endian.little);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final sample = (interleavedStereo[i].clamp(-1.0, 1.0) * 32767.0).round();
      byteData.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}
