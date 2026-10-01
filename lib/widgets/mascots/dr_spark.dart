import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'base_mascot.dart';

class DrSpark extends StatelessWidget {
  final double size;
  final MascotPose pose;
  final bool animate;

  const DrSpark({
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
      child: CustomPaint(painter: _DrSparkPainter(pose: pose)),
    );
  }
}

class _DrSparkPainter extends CustomPainter {
  final MascotPose pose;
  _DrSparkPainter({required this.pose});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ═══ WILD HAIR ═══
    final hairPaint = Paint()..color = const Color(0xFF1F2937);
    final hairPath = Path();
    hairPath.moveTo(w * 0.2, h * 0.30);
    hairPath.quadraticBezierTo(w * 0.15, h * 0.10, w * 0.30, h * 0.05);
    hairPath.quadraticBezierTo(w * 0.50, h * 0.02, w * 0.70, h * 0.05);
    hairPath.quadraticBezierTo(w * 0.85, h * 0.10, w * 0.80, h * 0.30);
    hairPath.close();
    canvas.drawPath(hairPath, hairPaint);

    // ═══ FACE ═══
    final facePaint = Paint()..color = const Color(0xFFFCD9B4);
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.35), w * 0.22, facePaint,
    );

    // ═══ GOGGLES ═══
    final gogglesFrame = Paint()
      ..color = AppColors.sciencePrimary
      ..strokeWidth = w * 0.025
      ..style = PaintingStyle.stroke;
    
    // Left lens
    canvas.drawCircle(
      Offset(w * 0.40, h * 0.35), w * 0.08, 
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(w * 0.40, h * 0.35), w * 0.08, gogglesFrame,
    );
    
    // Right lens
    canvas.drawCircle(
      Offset(w * 0.60, h * 0.35), w * 0.08, 
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(w * 0.60, h * 0.35), w * 0.08, gogglesFrame,
    );
    
    // Bridge
    canvas.drawLine(
      Offset(w * 0.48, h * 0.35),
      Offset(w * 0.52, h * 0.35),
      gogglesFrame,
    );

    // Eyes (in goggles)
    final eyePaint = Paint()..color = AppColors.scienceDark;
    canvas.drawCircle(Offset(w * 0.40, h * 0.35), w * 0.03, eyePaint);
    canvas.drawCircle(Offset(w * 0.60, h * 0.35), w * 0.03, eyePaint);

    // ═══ SMILE ═══
    final smilePaint = Paint()
      ..color = AppColors.scienceDark
      ..strokeWidth = w * 0.02
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final smilePath = Path();
    smilePath.moveTo(w * 0.43, h * 0.45);
    smilePath.quadraticBezierTo(
      w * 0.50, h * 0.50, w * 0.57, h * 0.45,
    );
    canvas.drawPath(smilePath, smilePaint);

    // ═══ LAB COAT ═══
    final coatPath = Path();
    coatPath.moveTo(w * 0.30, h * 0.55);
    coatPath.lineTo(w * 0.15, h * 0.95);
    coatPath.lineTo(w * 0.85, h * 0.95);
    coatPath.lineTo(w * 0.70, h * 0.55);
    coatPath.close();
    
    // Coat shadow
    canvas.drawPath(
      coatPath.shift(const Offset(0, 3)),
      Paint()..color = const Color(0xFFE5E7EB),
    );
    
    // Coat main
    canvas.drawPath(coatPath, Paint()..color = Colors.white);

    // Coat collar
    final collarPaint = Paint()
      ..color = AppColors.sciencePrimary
      ..strokeWidth = w * 0.015;
    canvas.drawLine(
      Offset(w * 0.42, h * 0.58),
      Offset(w * 0.50, h * 0.70),
      collarPaint,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.58),
      Offset(w * 0.50, h * 0.70),
      collarPaint,
    );

    // ═══ TEST TUBE ═══
    final tubePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015;
    
    final tubeRect = Rect.fromLTWH(
      w * 0.75, h * 0.65, w * 0.10, h * 0.25,
    );
    canvas.drawRect(tubeRect, tubePaint);

    // Liquid in tube
    final liquidRect = Rect.fromLTWH(
      w * 0.755, h * 0.78, w * 0.09, h * 0.11,
    );
    canvas.drawRect(liquidRect, Paint()..color = AppColors.sciencePrimary);

    // Bubbles
    canvas.drawCircle(
      Offset(w * 0.80, h * 0.75), w * 0.015,
      Paint()..color = AppColors.sciencePrimary.withOpacity(0.6),
    );
    canvas.drawCircle(
      Offset(w * 0.79, h * 0.71), w * 0.010,
      Paint()..color = AppColors.sciencePrimary.withOpacity(0.4),
    );
  }

  @override
  bool shouldRepaint(_DrSparkPainter oldDelegate) => 
      oldDelegate.pose != pose;
}
