import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import 'duolingo_button.dart';
import 'mascots/svg_mascot.dart';

class HeroCard extends StatelessWidget {
  final String chapterName;
  final String subjectName;
  final int currentLesson;
  final int totalLessons;
  final double progress;
  final VoidCallback? onResume;

  const HeroCard({
    super.key,
    required this.chapterName,
    required this.subjectName,
    required this.currentLesson,
    required this.totalLessons,
    required this.progress,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradientHero,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 4),
        boxShadow: AppShadows.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'CONTINUE LEARNING',
                  style: AppTextStyles.caption.copyWith(color: Colors.white),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 70,
                height: 70,
                child: const SvgMascot(type: MascotType.calculo, size: 70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              chapterName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$subjectName • Lesson $currentLesson of $totalLessons',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(height: 12, color: Colors.white.withOpacity(0.2)),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.gradientProgress,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% Complete',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          DuolingoButton(
            label: 'RESUME CHAPTER',
            color: Colors.white,
            darkColor: AppColors.borderMedium,
            textColor: AppColors.tertiary,
            icon: Icons.play_arrow_rounded,
            onPressed: onResume,
            height: 42,
            fontSize: 12,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }
}
