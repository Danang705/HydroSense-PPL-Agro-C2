import 'dart:math';
import 'package:flutter/material.dart';

import 'hydro_design.dart';

class CircularSensorGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String unit;
  final Color activeColor;

  const CircularSensorGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(130, 130),
            painter: _GaugePainter(
              value: value,
              min: min,
              max: max,
              activeColor: activeColor,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: HydroDesign.darkText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color activeColor;

  _GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 10.0;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // 1. Gambar cincin background abu-abu tipis (270 derajat / 1.5 * pi)
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75, // Mulai dari bawah-kiri (135 derajat)
      pi * 1.5,  // Rentang 270 derajat
      false,
      bgPaint,
    );

    // 2. Batasi nilai agar berada di rentang min - max
    final double clampedValue = value.clamp(min, max);
    final double sweepAngle = ((clampedValue - min) / (max - min)) * (pi * 1.5);

    // 3. Gambar cincin progres sensor dinamis jika nilai > min
    if (sweepAngle > 0.0) {
      final Paint progressPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi * 0.75,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.activeColor != activeColor;
  }
}
