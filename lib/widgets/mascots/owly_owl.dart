import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'base_mascot.dart';

class OwlyOwl extends StatelessWidget {
  final double size;
  final MascotPose pose;
  final bool animate;

  const OwlyOwl({
    super.key,
    this.size = 100,
    this.pose = MascotPose.idle,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return BaseMascot(
      size: size,
      animate: animate,
      child: CustomPaint(painter: _OwlyPainter(pose: pose)),
    );
  }
}

class _OwlyPainter extends CustomPainter {
  final MascotPose pose;
  _OwlyPainter({required this.pose});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ═══ BODY ═══
    final bodyPath = Path();
    bodyPath.moveTo(w * 0.5, h * 0.20);
    bodyPath.cubicTo(
      w * 0.15, h * 0.25,
      w * 0.15, h * 0.85,
      w * 0.5, h * 0.90,
    );
    bodyPath.cubicTo(
      w * 0.85, h * 0.85,
      w * 0.85, h * 0.25,
      w * 0.5, h * 0.20,
    );
    
    // Body shadow
    canvas.drawPath(
      bodyPath.shift(const Offset(0, 3)),
      Paint()..color = AppColors.englishDark,
    );
    // Body
    canvas.drawPath(bodyPath, Paint()..color = AppColors.englishPrimary);

    // ═══ BELLY ═══
    final bellyPath = Path();
    bellyPath.moveTo(w * 0.5, h * 0.45);
    bellyPath.cubicTo(
      w * 0.30, h * 0.50,
      w * 0.30, h * 0.80,
      w * 0.5, h * 0.85,
    );
    bellyPath.cubicTo(
      w * 0.70, h * 0.80,
      w * 0.70, h * 0.50,
      w * 0.5, h * 0.45,
    );
    canvas.drawPath(bellyPath, Paint()..color = const Color(0xFFFFF8DC));

    // ═══ EYES (Big round with glasses) ═══
    // Eye whites
    canvas.drawCircle(
      Offset(w * 0.38, h * 0.40), w * 0.12,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(w * 0.62, h * 0.40), w * 0.12,
      Paint()..color = Colors.white,
    );

    // Glasses frame
    final glassesPaint = Paint()
      ..color = AppColors.englishDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02;
    canvas.drawCircle(
      Offset(w * 0.38, h * 0.40), w * 0.13, glassesPaint,
    );
    canvas.drawCircle(
      Offset(w * 0.62, h * 0.40), w * 0.13, glassesPaint,
    );
    // Bridge
    canvas.drawLine(
      Offset(w * 0.51, h * 0.40),
      Offset(w * 0.49, h * 0.40),
      glassesPaint,
    );

    // Pupils
    final pupilPaint = Paint()..color = AppColors.textPrimary;
    canvas.drawCircle(Offset(w * 0.38, h * 0.40), w * 0.05, pupilPaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.40), w * 0.05, pupilPaint);

    // Eye shine
    canvas.drawCircle(
      Offset(w * 0.40, h * 0.38), w * 0.02,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(w * 0.64, h * 0.38), w * 0.02,
      Paint()..color = Colors.white,
    );

    // ═══ BEAK ═══
    final beakPath = Path();
    beakPath.moveTo(w * 0.5, h * 0.52);
    beakPath.lineTo(w * 0.46, h * 0.58);
    beakPath.lineTo(w * 0.54, h * 0.58);
    beakPath.close();
    canvas.drawPath(beakPath, Paint()..color = const Color(0xFFF97316));

    // ═══ GRADUATION CAP ═══
    // Cap base
    final capBase = Path();
    capBase.moveTo(w * 0.25, h * 0.20);
    capBase.lineTo(w * 0.75, h * 0.20);
    capBase.lineTo(w * 0.65, h * 0.13);
    capBase.lineTo(w * 0.35, h * 0.13);
    capBase.close();
    canvas.drawPath(capBase, Paint()..color = AppColors.textPrimary);

    // Cap top (square)
    final capTop = Rect.fromLTWH(w * 0.20, h * 0.08, w * 0.60, h * 0.06);
    canvas.drawRect(capTop, Paint()..color = AppColors.textPrimary);

    // Tassel
    canvas.drawLine(
      Offset(w * 0.75, h * 0.11),
      Offset(w * 0.85, h * 0.20),
      Paint()
        ..color = AppColors.warning
        ..strokeWidth = w * 0.015,
    );
    canvas.drawCircle(
      Offset(w * 0.85, h * 0.21), w * 0.02,
      Paint()..color = AppColors.warning,
    );

    // ═══ BOOK (in wing) ═══
    final bookRect = Rect.fromLTWH(w * 0.70, h * 0.65, w * 0.20, h * 0.15);
    canvas.drawRect(bookRect, Paint()..color = AppColors.warning);
    canvas.drawLine(
      Offset(w * 0.80, h * 0.65),
      Offset(w * 0.80, h * 0.80),
      Paint()
        ..color = Colors.white
        ..strokeWidth = w * 0.01,
    );
  }

  @override
  bool shouldRepaint(_OwlyPainter oldDelegate) => 
      oldDelegate.pose != pose;
}
