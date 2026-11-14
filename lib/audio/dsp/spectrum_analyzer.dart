import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

/// Pure-Dart Radix-2 Cooley-Tukey FFT computed on a window of real audio samples.
class RealFft {
  final int size; // Must be power of 2 (e.g. 256)
  late final Float64List _window;
  late final Float64List _cosTable;
  late final Float64List _sinTable;

  RealFft([this.size = 256]) {
    assert((size & (size - 1)) == 0, 'FFT size must be a power of 2');

    // Precompute Hanning window
    _window = Float64List(size);
    for (int i = 0; i < size; i++) {
      _window[i] = 0.5 * (1.0 - math.cos((2.0 * math.pi * i) / (size - 1)));
    }

    // Precompute trigonometric tables
    final half = size ~/ 2;
    _cosTable = Float64List(half);
    _sinTable = Float64List(half);
    for (int i = 0; i < half; i++) {
      final angle = -2.0 * math.pi * i / size;
      _cosTable[i] = math.cos(angle);
      _sinTable[i] = math.sin(angle);
    }
  }

  /// Computes normalized FFT magnitudes for [input] window of [size] samples.
  Float64List computeMagnitudes(Float64List input) {
    final real = Float64List(size);
    final imag = Float64List(size);

    // Apply Hanning window
    final len = math.min(input.length, size);
    for (int i = 0; i < len; i++) {
      real[i] = input[i] * _window[i];
    }

    // Bit-reversal permutation
    int j = 0;
    for (int i = 0; i < size - 1; i++) {
      if (i < j) {
        final tr = real[i];
        real[i] = real[j];
        real[j] = tr;
      }
      int k = size ~/ 2;
      while (k <= j) {
        j -= k;
        k ~/= 2;
      }
      j += k;
    }

    // Cooley-Tukey butterfly stages
    for (int len = 2; len <= size; len <<= 1) {
      final halfLen = len ~/ 2;
      final step = size ~/ len;

      for (int i = 0; i < size; i += len) {
        for (int k = 0; k < halfLen; k++) {
          final uReal = real[i + k];
          final uImag = imag[i + k];

          final cos = _cosTable[k * step];
          final sin = _sinTable[k * step];
          final vReal = real[i + k + halfLen] * cos - imag[i + k + halfLen] * sin;
          final vImag = real[i + k + halfLen] * sin + imag[i + k + halfLen] * cos;

          real[i + k] = uReal + vReal;
          imag[i + k] = uImag + vImag;
          real[i + k + halfLen] = uReal - vReal;
          imag[i + k + halfLen] = uImag - vImag;
        }
      }
    }

    // Calculate magnitude for positive frequency bins (0 .. size/2)
    final numBins = size ~/ 2;
    final magnitudes = Float64List(numBins);
    for (int i = 0; i < numBins; i++) {
      final mag = math.sqrt(real[i] * real[i] + imag[i] * imag[i]) / size;
      magnitudes[i] = mag;
    }
    return magnitudes;
  }
}

/// Computes log-spaced visual spectrum bands from a rendered audio buffer.
class SpectrumAnalyzer {
  static final RealFft _fft = RealFft(256);

  /// Group FFT bins into [numBands] log-scaled frequency bars.
  static List<double> computeBands(Float64List samples, {int offset = 0, int numBands = 16}) {
    if (samples.isEmpty) return List.filled(numBands, 0.0);

    // Extract mono window
    final window = Float64List(256);
    final totalSamples = samples.length;
    for (int i = 0; i < 256; i++) {
      final idx = (offset + i * 2) % totalSamples;
      // Average left and right channels
      window[i] = (samples[idx] + (idx + 1 < totalSamples ? samples[idx + 1] : 0.0)) * 0.5;
    }

    final rawMagnitudes = _fft.computeMagnitudes(window);

    // Map 128 FFT bins into log-scaled bands
    final result = List<double>.filled(numBands, 0.0);
    final numBins = rawMagnitudes.length;

    for (int b = 0; b < numBands; b++) {
      final startFrac = math.pow(b / numBands, 1.8);
      final endFrac = math.pow((b + 1) / numBands, 1.8);

      final startBin = (startFrac * numBins).floor().clamp(0, numBins - 1);
      final endBin = (endFrac * numBins).ceil().clamp(startBin + 1, numBins);

      double sum = 0.0;
      for (int i = startBin; i < endBin; i++) {
        sum += rawMagnitudes[i];
      }
      final avg = sum / (endBin - startBin);
      // Scale for display (normalized 0.0 to 1.0)
      result[b] = (avg * 8.0).clamp(0.04, 1.0);
    }

    return result;
  }

  /// Create a stream of real animated spectrum frames derived from [samples].
  static Stream<List<double>> createSpectrumStream(
    Float64List samples, {
    Duration frameInterval = const Duration(milliseconds: 50),
    int numBands = 16,
  }) async* {
    if (samples.isEmpty) {
      yield List.filled(numBands, 0.04);
      return;
    }

    int offset = 0;
    while (true) {
      yield computeBands(samples, offset: offset, numBands: numBands);
      await Future.delayed(frameInterval);
      offset = (offset + 512) % samples.length;
    }
  }
}
