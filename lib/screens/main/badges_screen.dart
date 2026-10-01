import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../services/firestore_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _badges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() => _isLoading = true);
    final badges = await _firestoreService.getAllBadges();
    if (mounted) {
      setState(() {
        _badges = badges;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final earnedBadges = _badges.where((b) => b['earned'] == true).toList();
    final lockedBadges = _badges.where((b) => b['earned'] != true).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.arrow_back_rounded),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emoji_events_rounded,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text('Badges', style: AppTextStyles.heading2),
                            ],
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),

                  // Progress Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradientHero,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppShadows.large,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.military_tech_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${earnedBadges.length} / ${_badges.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'Badges Earned',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _badges.isEmpty
                                    ? 0
                                    : earnedBadges.length / _badges.length,
                                minHeight: 10,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Earned Section
                  if (earnedBadges.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Earned (${earnedBadges.length})',
                              style: AppTextStyles.heading3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildBadgeCard(
                            earnedBadges[index],
                            true,
                            index,
                          );
                        }, childCount: earnedBadges.length),
                      ),
                    ),
                  ],

                  // Locked Section
                  if (lockedBadges.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Locked (${lockedBadges.length})',
                              style: AppTextStyles.heading3,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.9,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildBadgeCard(
                            lockedBadges[index],
                            false,
                            index,
                          );
                        }, childCount: lockedBadges.length),
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge, bool earned, int index) {
    return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _showBadgeDetail(badge, earned);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: earned ? AppColors.warning : AppColors.border,
                width: earned ? 2 : 1.5,
              ),
              boxShadow: earned
                  ? [
                      BoxShadow(
                        color: AppColors.warning.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: earned
                        ? AppColors.warning.withOpacity(0.15)
                        : AppColors.textMuted.withOpacity(0.1),
                  ),
                  child: Center(
                    child: earned
                        ? Text(
                            badge['icon'] ?? '🏆',
                            style: const TextStyle(fontSize: 32),
                          )
                        : Icon(
                            Icons.lock_rounded,
                            color: AppColors.textMuted,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  badge['name'] ?? 'Badge',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: earned ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: earned
                        ? AppColors.warning.withOpacity(0.15)
                        : AppColors.textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${badge['xpReward'] ?? 50} XP',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: earned ? AppColors.warning : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 60).ms)
        .scale(begin: const Offset(0.8, 0.8));
  }

  void _showBadgeDetail(Map<String, dynamic> badge, bool earned) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: earned
                      ? AppColors.warning.withOpacity(0.15)
                      : AppColors.textMuted.withOpacity(0.1),
                ),
                child: Center(
                  child: earned
                      ? Text(
                          badge['icon'] ?? '🏆',
                          style: const TextStyle(fontSize: 60),
                        )
                      : Icon(
                          Icons.lock_rounded,
                          color: AppColors.textMuted,
                          size: 40,
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(badge['name'] ?? 'Badge', style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              Text(
                badge['description'] ?? '',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: earned ? AppColors.success : AppColors.warning,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      earned
                          ? Icons.check_circle_rounded
                          : Icons.emoji_events_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      earned ? 'EARNED' : 'Earn ${badge['xpReward'] ?? 50} XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
