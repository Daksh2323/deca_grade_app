import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import 'mascots/svg_mascot.dart';
import 'duolingo_button.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData? icon;
  final String? emoji;
  final MascotType? mascot;
  final String? buttonLabel;
  final IconData? buttonIcon;
  final VoidCallback? onButtonPressed;
  final Color? buttonColor;

  const EmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.emoji,
    this.mascot,
    this.buttonLabel,
    this.buttonIcon,
    this.onButtonPressed,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mascot != null)
              Animate(
                effects: [
                  ScaleEffect(
                    begin: const Offset(0.5, 0.5),
                    curve: Curves.elasticOut,
                    duration: 800.ms,
                  ),
                  FadeEffect(duration: 400.ms),
                ],
                child: SvgMascot(type: mascot!, size: 140, animate: true),
              )
            else if (icon != null)
              Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: (buttonColor ?? AppColors.primary).withOpacity(
                        0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 70,
                      color: buttonColor ?? AppColors.primary,
                    ),
                  )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    curve: Curves.elasticOut,
                  )
                  .fadeIn()
            else if (emoji != null)
              Text(
                emoji!,
                style: const TextStyle(fontSize: 80),
              ).animate().scale(begin: const Offset(0.3, 0.3)).fadeIn(),

            const SizedBox(height: 24),

            Text(
                  title,
                  style: AppTextStyles.heading1.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                )
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.3, curve: Curves.easeOutCubic),

            const SizedBox(height: 8),

            Text(
              description,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: 30),
              DuolingoButton(
                label: buttonLabel!,
                color: buttonColor ?? AppColors.primary,
                darkColor: (buttonColor ?? AppColors.primary).withOpacity(0.7),
                icon: buttonIcon ?? Icons.arrow_forward_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onButtonPressed!();
                },
                height: 52,
                fontSize: 14,
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
            ],
          ],
        ),
      ),
    );
  }
}
