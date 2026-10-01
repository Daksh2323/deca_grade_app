import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'base_mascot.dart';

class IndyExplorer extends StatelessWidget {
  final double size;
  final MascotPose pose;
  final bool animate;

  const IndyExplorer({
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
      child: CustomPaint(painter: _IndyPainter(pose: pose)),
    );
  }
}

class _IndyPainter extends CustomPainter {
  final MascotPose pose;
  _IndyPainter({required this.pose});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ═══ SAFARI HAT ═══
    // Brim
    final brimPath = Path();
    brimPath.addOval(Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.70, h * 0.10));
    canvas.drawPath(brimPath, Paint()..color = const Color(0xFF92400E));

    // Top
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.30, h * 0.05, w * 0.40, h * 0.15),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(topRect, Paint()..color = const Color(0xFF92400E));

    // Hat band
    canvas.drawRect(
      Rect.fromLTWH(w * 0.30, h * 0.15, w * 0.40, h * 0.03),
      Paint()..color = const Color(0xFF451A03),
    );

    // ═══ FACE ═══
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.38), w * 0.20,
      Paint()..color = const Color(0xFFFCD9B4),
    );

    // ═══ EYES ═══
    final eyePaint = Paint()..color = AppColors.textPrimary;
    canvas.drawCircle(Offset(w * 0.42, h * 0.38), w * 0.03, eyePaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.38), w * 0.03, eyePaint);

    // Eye shine
    canvas.drawCircle(
      Offset(w * 0.43, h * 0.37), w * 0.01,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(w * 0.59, h * 0.37), w * 0.01,
      Paint()..color = Colors.white,
    );

    // ═══ SMILE ═══
    final smilePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = w * 0.02
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final smilePath = Path();
    smilePath.moveTo(w * 0.43, h * 0.47);
    smilePath.quadraticBezierTo(
      w * 0.50, h * 0.52, w * 0.57, h * 0.47,
    );
    canvas.drawPath(smilePath, smilePaint);

    // ═══ PINK JACKET ═══
    final jacketPath = Path();
    jacketPath.moveTo(w * 0.32, h * 0.55);
    jacketPath.lineTo(w * 0.18, h * 0.92);
    jacketPath.lineTo(w * 0.82, h * 0.92);
    jacketPath.lineTo(w * 0.68, h * 0.55);
    jacketPath.close();
    
    // Jacket shadow
    canvas.drawPath(
      jacketPath.shift(const Offset(0, 3)),
      Paint()..color = AppColors.sstDark,
    );
    // Jacket main
    canvas.drawPath(jacketPath, Paint()..color = AppColors.sstPrimary);

    // Jacket collar
    canvas.drawLine(
      Offset(w * 0.42, h * 0.58),
      Offset(w * 0.50, h * 0.68),
      Paint()
        ..color = AppColors.sstDark
        ..strokeWidth = w * 0.02,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.58),
      Offset(w * 0.50, h * 0.68),
      Paint()
        ..color = AppColors.sstDark
        ..strokeWidth = w * 0.02,
    );

    // ═══ MINI GLOBE ═══
    // Globe
    canvas.drawCircle(
      Offset(w * 0.75, h * 0.72), w * 0.12,
      Paint()..color = AppColors.info,
    );
    
    // Continents (simplified)
    final continentPaint = Paint()..color = AppColors.success;
    canvas.drawCircle(
      Offset(w * 0.72, h * 0.70), w * 0.03, continentPaint,
    );
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.74), w * 0.025, continentPaint,
    );

    // Globe stand
    canvas.drawLine(
      Offset(w * 0.75, h * 0.84),
      Offset(w * 0.75, h * 0.90),
      Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = w * 0.02,
    );
  }

  @override
  bool shouldRepaint(_IndyPainter oldDelegate) => 
      oldDelegate.pose != pose;
}
