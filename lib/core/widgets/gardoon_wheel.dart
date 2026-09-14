/// چرخ دو نیمه شب و روز — نماد گردون (design.md بخش ۱)
///
/// نیمه بالایی شب (سرمه‌ای + ماه + ستاره)، نیمه پایینی روز (طلایی + خورشید)،
/// محور مرکزی طلایی. با [spinning] می‌چرخد (تغییر فاز میزگرد).
library;

import 'dart:math';

import 'package:flutter/material.dart';



class GardoonWheel extends StatefulWidget {
  const GardoonWheel({
    super.key,
    this.size = 96,
    this.spinning = false,
  });

  final double size;
  final bool spinning;

  @override
  State<GardoonWheel> createState() => _GardoonWheelState();
}

class _GardoonWheelState extends State<GardoonWheel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(covariant GardoonWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning && !_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _WheelPainter(),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // نیمه شب (بالا)
    final nightPaint = Paint()..color = const Color(0xFF14203C);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi,
        pi, true, nightPaint);

    // نیمه روز (پایین)
    final dayPaint = Paint()..color = const Color(0xFFF0B429);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0,
        pi, true, dayPaint);

    // ماه در نیمه شب
    final moonPaint = Paint()..color = const Color(0xFFF5EFE6);
    canvas.drawCircle(
        center + Offset(-radius * 0.35, -radius * 0.35), radius * 0.18,
        moonPaint);

    // ستاره‌ها
    final starPaint = Paint()..color = Colors.white70;
    canvas.drawCircle(
        center + Offset(radius * 0.3, -radius * 0.55), radius * 0.045,
        starPaint);
    canvas.drawCircle(
        center + Offset(radius * 0.55, -radius * 0.3), radius * 0.035,
        starPaint);
    canvas.drawCircle(
        center + Offset(radius * 0.1, -radius * 0.75), radius * 0.03,
        starPaint);

    // خورشید در نیمه روز
    final sunPaint = Paint()..color = const Color(0xFF2B2118);
    canvas.drawCircle(
        center + Offset(radius * 0.0, radius * 0.4), radius * 0.16,
        sunPaint);
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final start = center +
          Offset(radius * 0.28 * cos(angle), radius * 0.4 + radius * 0.28 * sin(angle));
      final end = center +
          Offset(radius * 0.42 * cos(angle), radius * 0.4 + radius * 0.42 * sin(angle));
      canvas.drawLine(start, end, Paint()
        ..color = const Color(0xFF2B2118)
        ..strokeWidth = radius * 0.05
        ..strokeCap = StrokeCap.round);
    }

    // حلقه بیرونی
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.09
      ..color = const Color(0xFFC8871A);
    canvas.drawCircle(center, radius * 0.95, ringPaint);

    // محور مرکزی طلایی
    final hubPaint = Paint()..color = const Color(0xFFC8871A);
    canvas.drawCircle(center, radius * 0.16, hubPaint);
    canvas.drawCircle(
        center, radius * 0.16,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.03
          ..color = const Color(0xFF2B2118).withValues(alpha: 0.4));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}
