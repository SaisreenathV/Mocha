import 'dart:math' as math;
import 'package:flutter/material.dart';

class DepthDial extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double size;

  const DepthDial({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 10.0,
    this.max = 100.0,
    this.size = 110.0,
  });

  @override
  State<DepthDial> createState() => _DepthDialState();
}

class _DepthDialState extends State<DepthDial> {
  void _updateAngle(Offset localPosition) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // Angle from positive X axis clockwise in radians
    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;

    // Rotate so bottom-left (3 * pi / 4) is angle 0
    final startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    double relativeAngle = angle - startAngle;
    if (relativeAngle < 0) relativeAngle += 2 * math.pi;

    if (relativeAngle <= sweepAngle) {
      final ratio = (relativeAngle / sweepAngle).clamp(0.0, 1.0);
      final newValue = widget.min + ratio * (widget.max - widget.min);
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = ((widget.value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

    return GestureDetector(
      onPanDown: (details) => _updateAngle(details.localPosition),
      onPanUpdate: (details) => _updateAngle(details.localPosition),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _DialPainter(
            ratio: normalized,
            primaryColor: theme.colorScheme.primary,
            trackColor: theme.colorScheme.surfaceContainerHigh,
            outlineColor: theme.colorScheme.outline,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.value.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Hz',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final double ratio;
  final Color primaryColor;
  final Color trackColor;
  final Color outlineColor;

  _DialPainter({
    required this.ratio,
    required this.primaryColor,
    required this.trackColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8.0;

    const startAngle = 0.75 * math.pi;
    const sweepAngle = 1.5 * math.pi;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;

    // Draw background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Draw active arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * ratio,
      false,
      activePaint,
    );

    // Draw indicator tick knob
    final indicatorAngle = startAngle + sweepAngle * ratio;
    final knobOffset = Offset(
      center.dx + radius * math.cos(indicatorAngle),
      center.dy + radius * math.sin(indicatorAngle),
    );
    final knobPaint = Paint()..color = primaryColor;
    canvas.drawCircle(knobOffset, 5.0, knobPaint);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.ratio != ratio ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor;
  }
}
