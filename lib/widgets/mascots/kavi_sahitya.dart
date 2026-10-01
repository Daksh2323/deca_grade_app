import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'base_mascot.dart';

class KaviSahitya extends StatelessWidget {
  final double size;
  final MascotPose pose;
  final bool animate;

  const KaviSahitya({
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
      child: CustomPaint(painter: _KaviPainter(pose: pose)),
    );
  }
}

class _KaviPainter extends CustomPainter {
  final MascotPose pose;
  _KaviPainter({required this.pose});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ═══ TURBAN ═══
    // Turban wrapping
    final turbanPath = Path();
    turbanPath.moveTo(w * 0.20, h * 0.25);
    turbanPath.quadraticBezierTo(
      w * 0.50, h * 0.02, w * 0.80, h * 0.25,
    );
    turbanPath.lineTo(w * 0.80, h * 0.30);
    turbanPath.lineTo(w * 0.20, h * 0.30);
    turbanPath.close();
    canvas.drawPath(turbanPath, Paint()..color = AppColors.hindiPrimary);

    // Turban folds
    canvas.drawLine(
      Offset(w * 0.30, h * 0.15),
      Offset(w * 0.70, h * 0.15),
      Paint()
        ..color = AppColors.hindiDark
        ..strokeWidth = w * 0.015,
    );

    // ═══ PEACOCK FEATHER ═══
    final featherPaint = Paint()
      ..color = AppColors.hindiDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;
    
    final featherPath = Path();
    featherPath.moveTo(w * 0.75, h * 0.15);
    featherPath.quadraticBezierTo(
      w * 0.85, h * 0.05, w * 0.90, h * 0.02,
    );
    canvas.drawPath(featherPath, featherPaint);
    
    // Feather eye
    canvas.drawCircle(
      Offset(w * 0.90, h * 0.02), w * 0.02,
      Paint()..color = AppColors.info,
    );

    // ═══ FACE ═══
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.40), w * 0.20,
      Paint()..color = const Color(0xFFD8A574),
    );

    // ═══ TILAK ═══
    final tilakPath = Path();
    tilakPath.moveTo(w * 0.5, h * 0.28);
    tilakPath.lineTo(w * 0.48, h * 0.34);
    tilakPath.lineTo(w * 0.52, h * 0.34);
    tilakPath.close();
    canvas.drawPath(tilakPath, Paint()..color = AppColors.error);

    // ═══ EYES ═══
    final eyePaint = Paint()..color = AppColors.textPrimary;
    canvas.drawCircle(Offset(w * 0.42, h * 0.40), w * 0.025, eyePaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.40), w * 0.025, eyePaint);

    // ═══ MOUSTACHE ═══
    final moustachePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = w * 0.02
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromLTWH(w * 0.38, h * 0.44, w * 0.24, h * 0.08),
      0, 3.14, false, moustachePaint,
    );

    // ═══ SMILE ═══
    final smilePath = Path();
    smilePath.moveTo(w * 0.44, h * 0.52);
    smilePath.quadraticBezierTo(
      w * 0.50, h * 0.55, w * 0.56, h * 0.52,
    );
    canvas.drawPath(smilePath, moustachePaint);

    // ═══ CLOTHES (Traditional) ═══
    final clothesPath = Path();
    clothesPath.moveTo(w * 0.30, h * 0.58);
    clothesPath.lineTo(w * 0.18, h * 0.95);
    clothesPath.lineTo(w * 0.82, h * 0.95);
    clothesPath.lineTo(w * 0.70, h * 0.58);
    clothesPath.close();
    canvas.drawPath(clothesPath, Paint()..color = AppColors.hindiPrimary);

    // ═══ SCROLL ═══
    final scrollRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.70, h * 0.70, w * 0.20, h * 0.05),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(scrollRect, Paint()..color = const Color(0xFFFEF3C7));

    // ═══ QUILL ═══
    final quillPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = w * 0.015
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(w * 0.85, h * 0.72),
      Offset(w * 0.95, h * 0.60),
      quillPaint,
    );
  }

  @override
  bool shouldRepaint(_KaviPainter oldDelegate) => 
      oldDelegate.pose != pose;
}
