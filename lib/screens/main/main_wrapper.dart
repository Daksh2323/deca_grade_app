import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../widgets/mascots/svg_mascot.dart';
import 'home_screen.dart';
import 'learn_screen.dart';
import 'ai_tutor_screen.dart';
import 'profile_screen.dart';
import 'prep_hub_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LearnScreen(),
    AITutorScreen(),
    PrepHubScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  0,
                  Icons.home_rounded,
                  Icons.home_outlined,
                  'Home',
                ),
                _buildNavItem(
                  1,
                  Icons.menu_book_rounded,
                  Icons.menu_book_outlined,
                  'Learn',
                ),
                _buildCenterAI(2),
                _buildNavItem(
                  3,
                  Icons.rocket_launch_rounded,
                  Icons.rocket_outlined,
                  'Prep Hub',
                ),
                _buildNavItem(
                  4,
                  Icons.bar_chart_rounded,
                  Icons.bar_chart_outlined,
                  'Stats',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData filledIcon,
    IconData outlinedIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
            HapticFeedback.selectionClick();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: isActive ? 12 : 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.all(isActive ? 10 : 6),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.7),
                          ],
                        )
                      : null,
                  color: isActive ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isActive ? filledIcon : outlinedIcon,
                  color: isActive ? Colors.white : AppColors.textMuted,
                  size: isActive ? 24 : 22,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAI(int index) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
            HapticFeedback.mediumImpact();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.gradientAI,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.aiPrimary.withValues(
                        alpha: isActive ? 0.5 : 0.3,
                      ),
                      blurRadius: isActive ? 20 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: SvgMascot(
                      type: MascotType.aria,
                      size: 38,
                      animate: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Air',
                style: TextStyle(
                  color: isActive ? AppColors.aiDark : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
