import 'package:flutter/material.dart';
import 'dart:math' as math;

enum MascotPose { idle, thinking, celebrating, teaching }

class BaseMascot extends StatefulWidget {
  final Widget child;
  final double size;
  final bool animate;

  const BaseMascot({
    super.key,
    required this.child,
    this.size = 100,
    this.animate = true,
  });

  @override
  State<BaseMascot> createState() => _BaseMascotState();
}

class _BaseMascotState extends State<BaseMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = math.sin(_controller.value * math.pi) * 6;
        return Transform.translate(
          offset: Offset(0, -offset),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
