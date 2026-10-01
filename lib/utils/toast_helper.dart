import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';

class ToastHelper {
  static void showSuccess(BuildContext context, String message) {
    HapticFeedback.lightImpact();
    _showToast(
      context,
      message,
      icon: Icons.check_circle_rounded,
      color: AppColors.success,
      duration: const Duration(seconds: 2),
    );
  }

  static void showError(BuildContext context, String message) {
    HapticFeedback.heavyImpact();
    _showToast(
      context,
      message,
      icon: Icons.error_outline_rounded,
      color: AppColors.error,
      duration: const Duration(seconds: 3),
    );
  }

  static void showInfo(BuildContext context, String message) {
    HapticFeedback.selectionClick();
    _showToast(
      context,
      message,
      icon: Icons.info_outline_rounded,
      color: AppColors.aiPrimary,
      duration: const Duration(seconds: 2),
    );
  }

  static void showWarning(BuildContext context, String message) {
    HapticFeedback.mediumImpact();
    _showToast(
      context,
      message,
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
      duration: const Duration(seconds: 2),
    );
  }

  static void _showToast(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color color,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        duration: duration,
        elevation: 8,
      ),
    );
  }
}
