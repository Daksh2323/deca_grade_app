import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'base_mascot.dart';

class CalculoRobot extends StatelessWidget {
  final double size;
  final MascotPose pose;
  final bool animate;

  const CalculoRobot({
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
      child: CustomPaint(
        painter: _CalculoRobotPainter(pose: pose),
      ),
    );
  }
}

class _CalculoRobotPainter extends CustomPainter {
  final MascotPose pose;

  _CalculoRobotPainter({required this.pose});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ═══ ANTENNA ═══
    final antennaPaint = Paint()
      ..color = AppColors.mathPrimary
      ..strokeWidth = w * 0.03
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.15),
      Offset(w * 0.5, h * 0.05),
      antennaPaint,
    );

    // Antenna bulb (glowing)
    final bulbGlow = Paint()
      ..color = AppColors.mathPrimary.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(w * 0.5, h * 0.05), w * 0.05, bulbGlow);
    
    final bulb = Paint()..color = AppColors.warning;
    canvas.drawCircle(Offset(w * 0.5, h * 0.05), w * 0.04, bulb);

    // ═══ HEAD ═══
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.70, h * 0.45),
      Radius.circular(w * 0.15),
    );
    
    // Head shadow (3D depth)
    final headShadow = Paint()
      ..color = AppColors.mathDark;
    canvas.drawRRect(
      headRect.shift(const Offset(0, 3)),
      headShadow,
    );
    
    // Head main
    final headPaint = Paint()..color = AppColors.mathPrimary;
    canvas.drawRRect(headRect, headPaint);

    // ═══ SCREEN FACE ═══
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.22, w * 0.56, h * 0.30),
      Radius.circular(w * 0.08),
    );
    final screenPaint = Paint()..color = Colors.white;
    canvas.drawRRect(screenRect, screenPaint);

    // ═══ EYES ═══
    final eyePaint = Paint()..color = AppColors.mathDark;
    final eyeSize = pose == MascotPose.celebrating ? w * 0.05 : w * 0.04;
    
    // Left eye
    canvas.drawCircle(
      Offset(w * 0.36, h * 0.36), eyeSize, eyePaint,
    );
    // Right eye
    canvas.drawCircle(
      Offset(w * 0.64, h * 0.36), eyeSize, eyePaint,
    );

    // Eye shine
    final shinePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(w * 0.37, h * 0.35), eyeSize * 0.4, shinePaint,
    );
    canvas.drawCircle(
      Offset(w * 0.65, h * 0.35), eyeSize * 0.4, shinePaint,
    );

    // ═══ MOUTH ═══
    final mouthPaint = Paint()
      ..color = AppColors.mathDark
      ..strokeWidth = w * 0.02
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (pose == MascotPose.celebrating) {
      // Big smile
      final path = Path();
      path.moveTo(w * 0.40, h * 0.44);
      path.quadraticBezierTo(
        w * 0.50, h * 0.50, w * 0.60, h * 0.44,
      );
      canvas.drawPath(path, mouthPaint);
    } else {
      // Small smile
      final path = Path();
      path.moveTo(w * 0.43, h * 0.45);
      path.quadraticBezierTo(
        w * 0.50, h * 0.48, w * 0.57, h * 0.45,
      );
      canvas.drawPath(path, mouthPaint);
    }

    // ═══ BODY (Calculator) ═══
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.62, w * 0.56, h * 0.32),
      Radius.circular(w * 0.06),
    );
    
    // Body shadow
    canvas.drawRRect(
      bodyRect.shift(const Offset(0, 3)),
      Paint()..color = AppColors.mathDark,
    );
    
    // Body main
    canvas.drawRRect(bodyRect, headPaint);

    // Calculator buttons
    final buttonPaint = Paint()..color = Colors.white.withOpacity(0.9);
    final btnSize = w * 0.08;
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              w * 0.28 + (col * w * 0.15),
              h * 0.68 + (row * h * 0.11),
              btnSize,
              btnSize,
            ),
            Radius.circular(w * 0.015),
          ),
          buttonPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CalculoRobotPainter oldDelegate) => 
      oldDelegate.pose != pose;
}
