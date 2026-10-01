import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../config/theme.dart';
import 'base_mascot.dart';

class AriaOrb extends StatefulWidget {
  final double size;
  final MascotPose pose;
  final bool animate;

  const AriaOrb({
    super.key,
    this.size = 100,
    this.pose = MascotPose.idle,
    this.animate = true,
  });

  @override
  State<AriaOrb> createState() => _AriaOrbState();
}

class _AriaOrbState extends State<AriaOrb>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _rotateController]),
        builder: (context, child) {
          return CustomPaint(
            painter: _AriaPainter(
              pulse: _pulseController.value,
              rotation: _rotateController.value * 2 * math.pi,
              pose: widget.pose,
            ),
          );
        },
      ),
    );
  }
}

class _AriaPainter extends CustomPainter {
  final double pulse;
  final double rotation;
  final MascotPose pose;

  _AriaPainter({
    required this.pulse,
    required this.rotation,
    required this.pose,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w * 0.5;
    final centerY = h * 0.5;
    final radius = w * 0.30;

    // ═══ OUTER GLOW ═══
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.aiPrimary.withOpacity(0.4),
          AppColors.aiPrimary.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: radius * 2,
        ),
      );
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius * (1.8 + pulse * 0.2),
      glowPaint,
    );

    // ═══ MIDDLE GLOW ═══
    final midGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.aiBorder.withOpacity(0.6),
          AppColors.aiPrimary.withOpacity(0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: radius * 1.5,
        ),
      );
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius * 1.4,
      midGlowPaint,
    );

    // ═══ MAIN ORB ═══
    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFC7D2FE),
          AppColors.aiBorder,
          AppColors.aiDark,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(
        Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: radius,
        ),
      );
    canvas.drawCircle(Offset(centerX, centerY), radius, orbPaint);

    // ═══ EYES (Cute face) ═══
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - radius * 0.35, centerY - radius * 0.1),
        width: radius * 0.25,
        height: radius * 0.35,
      ),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + radius * 0.35, centerY - radius * 0.1),
        width: radius * 0.25,
        height: radius * 0.35,
      ),
      eyePaint,
    );

    // ═══ SMILE ═══
    final smilePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.015
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY + radius * 0.2),
        width: radius * 0.5,
        height: radius * 0.4,
      ),
      0, 3.14, false, smilePaint,
    );

    // ═══ ORBITING TECH SPARKLES ═══
    for (int i = 0; i < 3; i++) {
      final angle = rotation + (i * 2.09);  // 120° apart
      final sparkleX = centerX + math.cos(angle) * radius * 1.5;
      final sparkleY = centerY + math.sin(angle) * radius * 1.5;
      
      // Sparkle glow
      canvas.drawCircle(
        Offset(sparkleX, sparkleY),
        w * 0.03,
        Paint()..color = AppColors.aiBorder.withOpacity(0.4),
      );
      // Sparkle
      canvas.drawCircle(
        Offset(sparkleX, sparkleY),
        w * 0.02,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_AriaPainter oldDelegate) => true;
}
