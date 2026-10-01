import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/duolingo_button.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final int timeSpent;
  final String chapterTitle;
  final Map<String, Color> colors;
  final MascotType mascotType;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.timeSpent,
    required this.chapterTitle,
    required this.colors,
    required this.mascotType,
  });

  double get percentage => (score / totalQuestions) * 100;
  int get xpEarned => score * 10;

  String get performanceMessage {
    if (percentage == 100) return 'PERFECT! 🏆';
    if (percentage >= 80) return 'AMAZING! 🌟';
    if (percentage >= 60) return 'GREAT JOB! 👏';
    if (percentage >= 40) return 'GOOD EFFORT! 💪';
    return 'KEEP LEARNING! 📚';
  }

  Color get performanceColor {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  String get timeFormatted {
    final minutes = timeSpent ~/ 60;
    final seconds = timeSpent % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: SvgMascot(type: mascotType, size: 140, animate: true),
              ).animate().scale(
                begin: const Offset(0.3, 0.3),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 20),
              Text(
                performanceMessage,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: performanceColor,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
              const SizedBox(height: 8),
              Text(
                'You completed the quiz on\n$chapterTitle',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors['primary']!, colors['dark']!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  boxShadow: AppShadows.large,
                ),
                child: Column(
                  children: [
                    Text(
                      '$score / $totalQuestions',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${percentage.toInt()}% Accuracy',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('⚡', '$xpEarned', 'XP Earned'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildStat('⏱️', timeFormatted, 'Time'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildStat('✅', '$score', 'Correct'),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
              const Spacer(),
              DuolingoButton(
                label: 'CONTINUE',
                color: colors['primary']!,
                darkColor: colors['dark']!,
                icon: Icons.arrow_forward_rounded,
                height: 56,
                fontSize: 15,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
              ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                child: Text(
                  'Share Result',
                  style: TextStyle(
                    color: colors['primary'],
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ).animate().fadeIn(delay: 1100.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
