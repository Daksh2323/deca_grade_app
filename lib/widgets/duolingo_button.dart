import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

class DuolingoButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color darkColor;
  final Color textColor;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final double fontSize;
  final bool isLoading;
  final String? loadingLabel;

  const DuolingoButton({
    super.key,
    required this.label,
    required this.color,
    required this.darkColor,
    this.textColor = Colors.white,
    this.icon,
    this.onPressed,
    this.width,
    this.height = 48,
    this.fontSize = 13,
    this.isLoading = false,
    this.loadingLabel,
  });

  @override
  State<DuolingoButton> createState() => _DuolingoButtonState();
}

class _DuolingoButtonState extends State<DuolingoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled) {
          setState(() => _isPressed = true);
        }
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!isDisabled) {
          HapticFeedback.lightImpact();
          widget.onPressed!();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: widget.width ?? 200,
        height: widget.height + AppSizes.button3DDepth,
        child: Stack(
          children: [
            // Bottom (darker) - 3D shadow
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? widget.darkColor.withOpacity(0.4)
                      : widget.darkColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                ),
              ),
            ),
            // Top (main color)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              top: _isPressed ? AppSizes.button3DDepth : 0,
              left: 0,
              right: 0,
              child: Container(
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDisabled
                        ? [
                            widget.color.withOpacity(0.5),
                            widget.color.withOpacity(0.4),
                          ]
                        : [widget.color, widget.color.withOpacity(0.85)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                ),
                child: Center(
                  child: widget.isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: widget.textColor,
                                strokeWidth: 2.5,
                              ),
                            ),
                            if (widget.loadingLabel != null) ...[
                              const SizedBox(width: 10),
                              Text(
                                widget.loadingLabel!,
                                style: TextStyle(
                                  color: widget.textColor,
                                  fontSize: widget.fontSize,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: widget.textColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              widget.label,
                              style: TextStyle(
                                color: widget.textColor,
                                fontSize: widget.fontSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
