import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.background,
                      AppColors.primary.withOpacity(0.05),
                      AppColors.aiPrimary.withOpacity(0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animated glow
                  Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradientHero,
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.5),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text('📚', style: TextStyle(fontSize: 70)),
                      )
                      .animate()
                      .scale(
                        begin: const Offset(0.2, 0.2),
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 500.ms)
                      .then(delay: 200.ms)
                      .shimmer(
                        duration: 2000.ms,
                        color: Colors.white.withOpacity(0.6),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 1500.ms,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scale(
                        begin: const Offset(1.05, 1.05),
                        end: const Offset(1, 1),
                        duration: 1500.ms,
                        curve: Curves.easeInOut,
                      ),

                  const SizedBox(height: 40),

                  // App Name with gradient text
                  ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: AppColors.gradientHero,
                        ).createShader(bounds),
                        child: const Text(
                          'DecaGrade',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms)
                      .slideY(begin: 0.3, curve: Curves.easeOutCubic),

                  const SizedBox(height: 12),

                  // Tagline with animated dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Learn',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 700.ms),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ).animate().fadeIn(delay: 800.ms),
                      const SizedBox(width: 8),
                      Text(
                        'Grow',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 900.ms),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ).animate().fadeIn(delay: 1000.ms),
                      const SizedBox(width: 8),
                      Text(
                        'Excel',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 1100.ms),
                    ],
                  ),

                  const SizedBox(height: 80),

                  // Loading indicator
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  ).animate().fadeIn(delay: 1300.ms),
                ],
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.cardBg,
                      title: Text(
                        '🔧 Dev Tools',
                        style: AppTextStyles.heading2,
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.cloud_upload_rounded),
                            title: const Text('Seed Data'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/dev-seed');
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.pets_rounded),
                            title: const Text('Mascot Preview'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, '/mascot-preview');
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Text(
                  'Made with 💙 in India',
                  style: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 1500.ms),
            ),
          ],
        ),
      ),
    );
  }
}
