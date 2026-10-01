import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

enum MascotType { calculo, drSpark, owly, indy, kavi, aria }

class SvgMascot extends StatefulWidget {
  final MascotType type;
  final double size;
  final bool animate;
  final bool showRotation;

  const SvgMascot({
    super.key,
    required this.type,
    this.size = 100,
    this.animate = true,
    this.showRotation = false,
  });

  @override
  State<SvgMascot> createState() => _SvgMascotState();
}

class _SvgMascotState extends State<SvgMascot> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _rotateController;

  String get _assetPath {
    switch (widget.type) {
      case MascotType.calculo:
        return 'assets/mascots/calculo.svg';
      case MascotType.drSpark:
        return 'assets/mascots/dr_spark.svg';
      case MascotType.owly:
        return 'assets/mascots/owly.svg';
      case MascotType.indy:
        return 'assets/mascots/indy.svg';
      case MascotType.kavi:
        return 'assets/mascots/kavi.svg';
      case MascotType.aria:
        return 'assets/mascots/aria.svg';
    }
  }

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    if (widget.animate) {
      _floatController.repeat(reverse: true);
    }
    if (widget.showRotation) {
      _rotateController.repeat();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _rotateController]),
      builder: (context, child) {
        final floatOffset = math.sin(_floatController.value * math.pi) * 6;
        final rotation = widget.showRotation
            ? _rotateController.value * 2 * math.pi
            : 0.0;

        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: Transform.rotate(
            angle: rotation,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: child,
            ),
          ),
        );
      },
      child: SvgPicture.asset(
        _assetPath,
        width: widget.size,
        height: widget.size,
        placeholderBuilder: (context) => Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(widget.size / 2),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}
