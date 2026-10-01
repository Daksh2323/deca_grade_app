import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../screens/premium/checkout_screen.dart';
import 'duolingo_button.dart';
import 'empty_state.dart';
import 'error_state.dart';

typedef EmptyStateWidget = EmptyState;
typedef ErrorStateWidget = ErrorState;

class OfflineStateWidget extends StatelessWidget {
  const OfflineStateWidget({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.wifi_off_rounded,
      title: 'You are offline',
      message: 'Reconnect to the internet and try again.',
      actionLabel: onRetry == null ? null : 'RETRY',
      onAction: onRetry,
    );
  }
}

class UnauthorizedStateWidget extends StatelessWidget {
  const UnauthorizedStateWidget({super.key, this.onLogin});

  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.lock_clock_rounded,
      title: 'Session expired',
      message: 'Please sign in again to continue.',
      actionLabel: 'LOG IN AGAIN',
      onAction:
          onLogin ??
          () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/onboarding',
            (route) => false,
          ),
    );
  }
}

class PremiumLockedWidget extends StatelessWidget {
  const PremiumLockedWidget({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return _StatePanel(
      icon: Icons.lock_outline_rounded,
      iconColor: AppColors.warning,
      title: 'Premium feature locked',
      message: message ?? 'Upgrade to Pro to unlock this feature.',
      actionLabel: 'UPGRADE TO PRO',
      actionIcon: Icons.lock_open_rounded,
      actionColor: AppColors.warning,
      onAction: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.iconColor,
    this.actionLabel,
    this.actionIcon,
    this.actionColor,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? iconColor;
  final String? actionLabel;
  final IconData? actionIcon;
  final Color? actionColor;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor ?? AppColors.primary, size: 56),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: DuolingoButton(
                    label: actionLabel!,
                    color: actionColor ?? AppColors.primary,
                    darkColor: actionColor == AppColors.warning
                        ? const Color(0xFFD97706)
                        : AppColors.primaryDark,
                    icon: actionIcon ?? Icons.refresh_rounded,
                    onPressed: onAction,
                    height: 48,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
