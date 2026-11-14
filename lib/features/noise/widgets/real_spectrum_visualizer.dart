import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../audio/dsp/brown_noise_synthesizer.dart';
import '../../../audio/dsp/spectrum_analyzer.dart';
import '../../../domain/noise_params.dart';

class RealSpectrumVisualizer extends StatefulWidget {
  final NoiseParams params;
  final bool isPlaying;
  final int numBands;
  final double height;

  const RealSpectrumVisualizer({
    super.key,
    required this.params,
    required this.isPlaying,
    this.numBands = 16,
    this.height = 64,
  });

  @override
  State<RealSpectrumVisualizer> createState() => _RealSpectrumVisualizerState();
}

class _RealSpectrumVisualizerState extends State<RealSpectrumVisualizer> {
  Float64List? _renderedBuffer;
  StreamSubscription<List<double>>? _streamSub;
  List<double> _currentBands = const [];

  @override
  void initState() {
    super.initState();
    _currentBands = List.filled(widget.numBands, 0.05);
    _renderAndStart();
  }

  @override
  void didUpdateWidget(RealSpectrumVisualizer old) {
    super.didUpdateWidget(old);
    if (old.params != widget.params) {
      _renderAndStart();
    } else if (old.isPlaying != widget.isPlaying) {
      if (widget.isPlaying) {
        _startStream();
      } else {
        _streamSub?.cancel();
        setState(() {
          _currentBands = List.filled(widget.numBands, 0.05);
        });
      }
    }
  }

  void _renderAndStart() {
    _streamSub?.cancel();
    // Render short 2-second buffer for FFT analysis
    final synth = BrownNoiseSynthesizer();
    _renderedBuffer = synth.renderStereo(widget.params, seconds: 2.0, sampleRate: 44100);

    if (widget.isPlaying) {
      _startStream();
    } else {
      setState(() {
        _currentBands = List.filled(widget.numBands, 0.05);
      });
    }
  }

  void _startStream() {
    final buf = _renderedBuffer;
    if (buf == null) return;

    _streamSub?.cancel();
    _streamSub = SpectrumAnalyzer.createSpectrumStream(
      buf,
      numBands: widget.numBands,
      frameInterval: const Duration(milliseconds: 40),
    ).listen((bands) {
      if (mounted) {
        setState(() {
          _currentBands = bands;
        });
      }
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Real-time audio frequency spectrum analyzer',
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SpectrumPainter(
            bands: _currentBands,
            color: cs.primary,
            trackColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final List<double> bands;
  final Color color;
  final Color trackColor;

  _SpectrumPainter({
    required this.bands,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bands.isEmpty) return;

    final n = bands.length;
    final totalSpacing = (n - 1) * 3.0;
    final barWidth = ((size.width - totalSpacing) / n).clamp(2.0, 16.0);
    final cornerRadius = Radius.circular(barWidth * 0.4);

    final bgPaint = Paint()..color = trackColor;
    final barPaint = Paint()..color = color;

    for (int i = 0; i < n; i++) {
      final x = i * (barWidth + 3.0);
      final heightFrac = bands[i].clamp(0.04, 1.0);
      final barHeight = size.height * heightFrac;
      final y = size.height - barHeight;

      // Draw subtle background slot
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barWidth, size.height),
          cornerRadius,
        ),
        bgPaint,
      );

      // Draw active FFT magnitude bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          cornerRadius,
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) {
    return old.bands != bands || old.color != color;
  }
}
