import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../config/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _floatController;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.play_circle_fill_rounded,
      'iconColor': const Color(0xFF4F8EF7),
      'title': 'Learn with\nAnimations',
      'subtitle': 'Complex topics made simple with\nstunning animated videos',
      'gradient': AppColors.gradientBlue,
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'iconColor': const Color(0xFF8B5CF6),
      'title': 'AI Tutor\nAvailable 24/7',
      'subtitle': 'Ask anything, anytime.\nGet instant smart answers',
      'gradient': AppColors.gradientPurple,
    },
    {
      'icon': Icons.emoji_events_rounded,
      'iconColor': const Color(0xFFF59E0B),
      'title': 'Track Your\nProgress',
      'subtitle': 'Quizzes, streaks & leaderboards\nto keep you motivated',
      'gradient': AppColors.gradientOrange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _skipToLogin() {
    HapticFeedback.selectionClick();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated gradient background blob
          _buildBackgroundBlob(),
          
          // Stars
          _buildStars(),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextButton(
                      onPressed: _skipToLogin,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: 
                            AppColors.cardBg.withOpacity(0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Skip',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16, color: AppColors.textPrimary),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.3),
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildSlide(_slides[index], index);
                    },
                  ),
                ),

                _buildBottomSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlob() {
    return Positioned(
      top: -100,
      right: -100,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatController.value * 20),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _slides[_currentPage]['iconColor']
                        .withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStars() {
    final random = math.Random(42);
    return Stack(
      children: List.generate(30, (index) {
        return Positioned(
          top: random.nextDouble() *
              MediaQuery.of(context).size.height,
          left: random.nextDouble() *
              MediaQuery.of(context).size.width,
          child: Container(
            width: random.nextDouble() * 3 + 1,
            height: random.nextDouble() * 3 + 1,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                random.nextDouble() * 0.6 + 0.2,
              ),
              borderRadius: BorderRadius.circular(50),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .fadeIn(
                delay: (random.nextDouble() * 2000).ms,
                duration: 1500.ms,
              )
              .then()
              .fadeOut(duration: 1500.ms),
        );
      }),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide, int index) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Animated Icon
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, math.sin(_floatController.value * 
                      math.pi * 2) * 8),
                  child: child,
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          slide['iconColor'].withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Icon container
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: slide['gradient'],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: slide['iconColor'].withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      slide['icon'],
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                .animate(key: ValueKey(index))
                .scale(
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 30),

            // Title
            Text(
              slide['title'],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.2,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate(key: ValueKey('title$index'))
                .fadeIn(delay: 200.ms, duration: 500.ms)
                .slideY(begin: 0.3, curve: Curves.easeOutCubic),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              slide['subtitle'],
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            )
                .animate(key: ValueKey('sub$index'))
                .fadeIn(delay: 400.ms, duration: 500.ms)
                .slideY(begin: 0.3, curve: Curves.easeOutCubic),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: _currentPage == index
                      ? const LinearGradient(
                          colors: AppColors.gradientBlue,
                        )
                      : null,
                  color: _currentPage == index
                      ? null
                      : AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: _currentPage == index
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Next button with animation
          GestureDetector(
            onTap: _nextPage,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.gradientBlue,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPage == _slides.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentPage == _slides.length - 1
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 500.ms)
              .slideY(begin: 0.5, curve: Curves.easeOutCubic),

          const SizedBox(height: 20),

          TextButton(
            onPressed: _skipToLogin,
            child: RichText(
              text: const TextSpan(
                text: 'Already have an account? ',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'Login',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }
}
