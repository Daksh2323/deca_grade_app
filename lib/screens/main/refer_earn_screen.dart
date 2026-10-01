import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/duolingo_button.dart';

class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _referralCode = '';
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;
  bool _showQR = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _firestoreService.getUserReferralCode(),
      _firestoreService.getReferralStats(),
      _firestoreService.getTopReferrers(),
    ]);

    if (mounted) {
      setState(() {
        _referralCode = results[0]?.toString() ?? '';
        _stats = results[1] as Map<String, dynamic>;
        _leaderboard = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  String _getShareMessage() {
    return '''🎓 Join me on DecaGrade - the AI Study App!

📚 Learn from Class 10 CBSE experts
🤖 Get instant help from Air AI
🎯 Practice with quizzes & flashcards
📸 Solve any math problem with your camera
🔥 And much more!

Use my code: *$_referralCode* to get *100 XP bonus*!

Download now: https://studyverse.app''';
  }

  void _shareCode() {
    HapticFeedback.mediumImpact();
    Share.share(_getShareMessage(), subject: 'Join me on DecaGrade! 🎓');
  }

  void _copyCode() {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text('Copied: $_referralCode'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareViaWhatsApp() {
    HapticFeedback.mediumImpact();
    final message = Uri.encodeComponent(_getShareMessage());
    Share.share(_getShareMessage(), subject: 'Join DecaGrade! 🎓');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(),
              _buildHeroSection(),
              _buildReferralCodeCard(),
              _buildShareButtons(),
              _buildStatsSection(),
              _buildHowItWorks(),
              if (_leaderboard.isNotEmpty) _buildLeaderboard(),
              _buildRewardTiers(),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
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
              children: [
                const Text('🎁', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text('Refer & Earn', style: AppTextStyles.heading2),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                setState(() => _showQR = !_showQR);
                HapticFeedback.selectionClick();
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.aiLightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.aiBorder),
                ),
                child: Icon(
                  _showQR ? Icons.qr_code : Icons.qr_code_scanner_rounded,
                  color: AppColors.aiDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.gradientHero,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.large,
          ),
          child: Column(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 60))
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(
                    begin: -0.05,
                    end: 0.05,
                    duration: 1500.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .rotate(
                    begin: 0.05,
                    end: -0.05,
                    duration: 1500.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 12),
              const Text(
                'Refer Friends,\nEarn XP Rewards!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⚡', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 6),
                    Text(
                      '200 XP per friend + 100 XP for them!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.2),
    );
  }

  Widget _buildReferralCodeCard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.aiBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.aiPrimary.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'YOUR REFERRAL CODE',
                style: TextStyle(
                  color: AppColors.aiPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),

              if (_showQR)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _referralCode,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    embeddedImage: null,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ).animate().scale(begin: const Offset(0.8, 0.8))
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.aiPrimary.withOpacity(0.1),
                        AppColors.aiPrimary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.aiPrimary,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _referralCode,
                        style: TextStyle(
                          color: AppColors.aiDark,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DuolingoButton(
                      label: 'COPY',
                      color: AppColors.aiPrimary,
                      darkColor: AppColors.aiDark,
                      icon: Icons.copy_rounded,
                      onPressed: _copyCode,
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DuolingoButton(
                      label: 'SHARE',
                      color: AppColors.success,
                      darkColor: const Color(0xFF047857),
                      icon: Icons.share_rounded,
                      onPressed: _shareCode,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
    );
  }

  Widget _buildShareButtons() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📢', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('Share Via', style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSocialButton(
                    'WhatsApp',
                    '💚',
                    const Color(0xFF25D366),
                    _shareViaWhatsApp,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSocialButton(
                    'Instagram',
                    '📷',
                    const Color(0xFFE1306C),
                    _shareCode,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSocialButton(
                    'More',
                    '🔗',
                    AppColors.primary,
                    _shareCode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    String label,
    String emoji,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalReferrals = _stats['totalReferrals'] ?? 0;
    final totalXP = _stats['totalXpEarned'] ?? 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('Your Stats', style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '👥',
                    '$totalReferrals',
                    'Friends Referred',
                    AppColors.aiPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    '⚡',
                    '$totalXP',
                    'XP Earned',
                    AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
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
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.gradientAI),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.aiPrimary.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SvgMascot(
                    type: MascotType.aria,
                    size: 40,
                    animate: false,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'How it works? 🎯',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStep(
                '1️⃣',
                'Share your code',
                'Send code to friends via WhatsApp',
              ),
              _buildStep(
                '2️⃣',
                'Friend signs up',
                'They install DecaGrade and enter your code',
              ),
              _buildStep(
                '3️⃣',
                'Both get XP!',
                'You get 200 XP, they get 100 XP',
              ),
              _buildStep(
                '4️⃣',
                'Refer more',
                'No limit on how many you can refer!',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('Top Referrers', style: AppTextStyles.heading3),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'THIS MONTH',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_leaderboard.take(5).toList().asMap().entries.map((entry) {
              return _buildLeaderRow(entry.value, entry.key);
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderRow(Map<String, dynamic> leader, int index) {
    final medals = ['🥇', '🥈', '🥉', '4️⃣', '5️⃣'];
    final isCurrentUser = leader['isCurrentUser'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.aiLightBg : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser ? AppColors.aiPrimary : AppColors.border,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(medals[index], style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      leader['name'] ?? 'Student',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.aiPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${leader['totalReferrals']} referrals',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 3),
                Text(
                  '${leader['totalXpEarned']}',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.1);
  }

  Widget _buildRewardTiers() {
    final totalReferrals = _stats['totalReferrals'] ?? 0;

    final tiers = [
      {'count': 1, 'reward': '⚡ 200 XP', 'name': 'First Friend'},
      {'count': 5, 'reward': '🎖️ Badge + 500 XP', 'name': 'Sharing Star'},
      {'count': 10, 'reward': '🏆 Badge + 1000 XP', 'name': 'Influencer'},
      {'count': 25, 'reward': '👑 Badge + 3000 XP', 'name': 'Legend'},
      {'count': 50, 'reward': '💎 Badge + 10000 XP', 'name': 'Ultimate'},
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('Milestone Rewards', style: AppTextStyles.heading3),
              ],
            ),
            const SizedBox(height: 12),
            ...tiers.map((tier) {
              final count = (tier['count'] as num?)?.toInt() ?? 0;
              final isUnlocked = totalReferrals >= count;
              final index = tiers.indexOf(tier);
              final isCurrent =
                  totalReferrals < count &&
                  (index == 0 ||
                      totalReferrals >=
                          ((tiers[index - 1]['count'] as num?)?.toInt() ?? 0));

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUnlocked
                        ? AppColors.success
                        : isCurrent
                        ? AppColors.warning
                        : AppColors.border,
                    width: isUnlocked || isCurrent ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? AppColors.success
                            : AppColors.textMuted.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: isUnlocked
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 24,
                              )
                            : Text(
                                '$count',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tier['name']?.toString() ?? '',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (isUnlocked) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'UNLOCKED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            'Refer $count friends',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      tier['reward']?.toString() ?? '',
                      style: TextStyle(
                        color: isUnlocked
                            ? AppColors.success
                            : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
