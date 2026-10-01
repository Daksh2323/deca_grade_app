import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import 'duolingo_button.dart';

class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryLabel;

  const ErrorState({
    super.key,
    this.title = 'Oops! Something went wrong',
    required this.message,
    this.icon,
    this.onRetry,
    this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.error.withOpacity(0.2),
                        AppColors.error.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon ?? Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 60,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  curve: Curves.elasticOut,
                  duration: 800.ms,
                )
                .then()
                .shimmer(
                  duration: 1500.ms,
                  color: AppColors.error.withOpacity(0.3),
                ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.heading1.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms),
            if (onRetry != null) ...[
              const SizedBox(height: 30),
              DuolingoButton(
                label: retryLabel ?? 'TRY AGAIN',
                color: AppColors.primary,
                darkColor: AppColors.primaryDark,
                icon: Icons.refresh_rounded,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onRetry!();
                },
                height: 52,
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
            ],
          ],
        ),
      ),
    );
  }
}
