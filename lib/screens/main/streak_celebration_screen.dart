import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/mascots/svg_mascot.dart';

class StreakCelebrationScreen extends StatefulWidget {
  final int streak;
  final int maxStreak;
  final bool isNewRecord;

  const StreakCelebrationScreen({
    super.key,
    required this.streak,
    required this.maxStreak,
    this.isNewRecord = false,
  });

  @override
  State<StreakCelebrationScreen> createState() =>
      _StreakCelebrationScreenState();
}

class _StreakCelebrationScreenState extends State<StreakCelebrationScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _flameController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _flameController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    // Start celebration
    Future.delayed(const Duration(milliseconds: 400), () {
      _confettiController.play();
      HapticFeedback.heavyImpact();
    });

    // Multiple haptic pulses
    Future.delayed(const Duration(milliseconds: 600), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _flameController.dispose();
    super.dispose();
  }

  String _getMessage() {
    if (widget.streak == 1) return 'Great start! 🌱';
    if (widget.streak < 7) return 'Keep it going! 🚀';
    if (widget.streak == 7) return 'A WEEK STREAK! 🔥';
    if (widget.streak < 30) return 'You\'re on fire! 🔥';
    if (widget.streak == 30) return 'MONTHLY MASTER! 👑';
    if (widget.streak < 100) return 'Unstoppable! 💪';
    if (widget.streak == 100) return 'LEGENDARY! 🏆';
    return 'INCREDIBLE! ⭐';
  }

  Color _getFlameColor() {
    if (widget.streak < 7) return const Color(0xFFF59E0B);
    if (widget.streak < 30) return const Color(0xFFEF4444);
    if (widget.streak < 100) return const Color(0xFFDC2626);
    return const Color(0xFF991B1B);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  // Animated Flame
                  AnimatedBuilder(
                        animation: _flameController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1 + (_flameController.value * 0.1),
                            child: Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    _getFlameColor().withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '🔥',
                                style: TextStyle(
                                  fontSize: 180,
                                  shadows: [
                                    Shadow(
                                      color: _getFlameColor(),
                                      blurRadius:
                                          40 + (_flameController.value * 20),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                      .animate()
                      .scale(
                        begin: const Offset(0.3, 0.3),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(),

                  const SizedBox(height: 20),

                  // Streak Number
                  Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${widget.streak}',
                            style: TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.w900,
                              color: _getFlameColor(),
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'DAYS',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.3, curve: Curves.easeOutBack),

                  const SizedBox(height: 8),

                  Text(
                    _getMessage(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _getFlameColor(),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

                  const SizedBox(height: 20),

                  // New Record Badge
                  if (widget.isNewRecord)
                    Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.warning,
                                AppColors.warning.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warning.withOpacity(0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🏆', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text(
                                'NEW RECORD!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 900.ms)
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          curve: Curves.elasticOut,
                        ),

                  const SizedBox(height: 30),

                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '🎯',
                          '${widget.maxStreak}',
                          'Best Streak',
                          AppColors.aiPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          '⚡',
                          '+${widget.streak * 10}',
                          'XP Earned',
                          AppColors.success,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2),

                  const Spacer(),

                  // Motivational message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.aiLightBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.aiBorder),
                    ),
                    child: Row(
                      children: [
                        const SvgMascot(
                          type: MascotType.aria,
                          size: 50,
                          animate: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Amazing dedication! Come back tomorrow to keep your streak alive! 🚀',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3),

                  const SizedBox(height: 20),

                  // Continue Button
                  DuolingoButton(
                    label: 'CONTINUE LEARNING',
                    color: _getFlameColor(),
                    darkColor: _getFlameColor().withOpacity(0.7),
                    icon: Icons.arrow_forward_rounded,
                    width: double.infinity,
                    height: 56,
                    fontSize: 15,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                  ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.3),
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: [
                _getFlameColor(),
                AppColors.primary,
                AppColors.aiPrimary,
                AppColors.warning,
                AppColors.success,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
