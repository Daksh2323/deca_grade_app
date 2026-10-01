import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/premium_status_listener.dart';
import '../../widgets/premium_status_listener.dart'
    show PremiumStatusListenerWithData;
import '../premium/checkout_screen.dart';
import 'analytics_screen.dart';
import 'refer_earn_screen.dart';
import 'legal_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _user;
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = await _firestoreService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  int _getLevel(int xp) => (xp / 200).floor() + 1;

  void _showEditNameDialog() {
    HapticFeedback.mediumImpact();
    final nameController = TextEditingController(text: _user?.name ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Name', style: AppTextStyles.heading2),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await _firestoreService.updateUser({'name': newName});
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name updated! 🎉'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            Text('Logout?', style: AppTextStyles.heading2),
          ],
        ),
        content: Text(
          'You\'ll need to login again to access your account.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/onboarding',
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    HapticFeedback.heavyImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error),
            const SizedBox(width: 12),
            Text('Delete Account?', style: AppTextStyles.heading2),
          ],
        ),
        content: Text(
          'This action CANNOT be undone.\n\n'
          'All your data, progress, and XP will be permanently deleted.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete Forever',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.deleteAccount();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/onboarding',
            (route) => false,
          );
        }
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account. $error'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildMembershipCard() {
    // ⚡ OPTIMIZATION: Scoped StreamBuilder prevents entire profile from rebuilding
    return PremiumStatusListenerWithData(
      builder: (context, isPremium, data, expiryDate) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPremium
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPremium
                    ? AppColors.warning
                    : AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPremium
                          ? Icons.workspace_premium_rounded
                          : Icons.lock_outline_rounded,
                      color: isPremium
                          ? AppColors.warning
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPremium ? 'DecaGrade Pro Member' : 'Free Plan',
                        style: AppTextStyles.heading2,
                      ),
                    ),
                    if (isPremium)
                      const Icon(Icons.check_circle, color: AppColors.success),
                  ],
                ),
                const SizedBox(height: 8),
                if (isPremium) ...[
                  Text(
                    'Plan: ${data['plan'] ?? 'DecaGrade Pro'}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    'Expires on: ${expiryDate == null ? 'No expiry set' : DateFormat('dd MMM yyyy').format(expiryDate)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ] else
                  Text(
                    'Unlock unlimited AI and premium content.',
                    style: AppTextStyles.bodyMedium,
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPremium
                          ? AppColors.cardBg
                          : AppColors.primary,
                      foregroundColor: isPremium
                          ? AppColors.textPrimary
                          : Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: Text(isPremium ? 'Manage Plan' : 'Upgrade to Pro'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

    final name = _user?.name ?? 'Student';
    final email = _user?.email ?? '';
    final xp = _user?.xp ?? 0;
    final streak = _user?.streak ?? 0;
    final level = _getLevel(xp);
    // final badges = _user?.badges.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: true,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ═══ HERO HEADER ═══
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientHero,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: AppShadows.large,
                  ),
                  child: Column(
                    children: [
                      // Top row with title
                      Row(
                        children: [
                          Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _showEditNameDialog,
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Avatar with mascot
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.aiLightBg,
                            borderRadius: BorderRadius.circular(56),
                          ),
                          child: const Center(
                            child: SvgMascot(type: MascotType.aria, size: 90),
                          ),
                        ),
                      ).animate().scale(
                        begin: const Offset(0.5, 0.5),
                        curve: Curves.elasticOut,
                      ),

                      const SizedBox(height: 16),

                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 4),

                      // Email
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 12),

                      // Level badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🏆', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              'Level $level',
                              style: TextStyle(
                                color: AppColors.tertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).scale(),
                    ],
                  ),
                ),
              ),

              // ═══ STATS ROW ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '🔥',
                          '$streak',
                          'Day Streak',
                          AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          '⚡',
                          '$xp',
                          'Total XP',
                          AppColors.aiPrimary,
                        ),
                      ),
                      // const SizedBox(width: 10),
                      // Expanded(
                      //   child: _buildStatCard(
                      //     '🏆',
                      //     '$badges',
                      //     'Badges',
                      //     AppColors.success,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(child: _buildMembershipCard()),

              // ═══ ACCOUNT SETTINGS ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Account', style: AppTextStyles.caption),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        /*
                        _buildTile(
                          icon: Icons.emoji_events_rounded,
                          iconColor: AppColors.warning,
                          title: 'My Badges',
                          subtitle: '${_user?.badges.length ?? 0} badges earned',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BadgesScreen(),
                              ),
                            );
                          },

                          Widget _buildMembershipCard() {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid == null) return const SizedBox.shrink();

                            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                              builder: (context, snapshot) {
                                final data = snapshot.data?.data() ?? <String, dynamic>{};
                                final expiryValue = data['expiryDate'];
                                final expiryDate = expiryValue is Timestamp
                                    ? expiryValue.toDate()
                                    : expiryValue is DateTime
                                    ? expiryValue
                                    : null;
                                final isActive = expiryDate == null || expiryDate.isAfter(DateTime.now());
                                final isPremium = isActive &&
                                    (data['isPro'] == true || data['isUltimate'] == true);

                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isPremium
                                          ? AppColors.primary.withValues(alpha: 0.1)
                                          : AppColors.cardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isPremium
                                            ? AppColors.warning
                                            : AppColors.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isPremium
                                                  ? Icons.workspace_premium_rounded
                                                  : Icons.lock_outline_rounded,
                                              color: isPremium ? AppColors.warning : AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                isPremium ? 'DecaGrade Pro Member' : 'Free Plan',
                                                style: AppTextStyles.heading2,
                                              ),
                                            ),
                                            if (isPremium)
                                              const Icon(Icons.check_circle, color: AppColors.success),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (isPremium) ...[
                                          Text('Plan: ${data['plan'] ?? 'DecaGrade Pro'}',
                                              style: AppTextStyles.bodyMedium),
                                          Text(
                                            'Expires on: ${expiryDate == null ? 'No expiry set' : DateFormat('dd MMM yyyy').format(expiryDate)}',
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        ] else
                                          Text(
                                            'Unlock unlimited AI and premium content.',
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const CheckoutScreen(),
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isPremium
                                                  ? AppColors.cardBg
                                                  : AppColors.primary,
                                              foregroundColor: isPremium
                                                  ? AppColors.textPrimary
                                                  : Colors.white,
                                              minimumSize: const Size(double.infinity, 45),
                                            ),
                                            child: Text(isPremium ? 'Manage Plan' : 'Upgrade to Pro'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        ),
                        _buildDivider(),
                        */
                        _buildTile(
                          icon: Icons.analytics_rounded,
                          iconColor: AppColors.aiPrimary,
                          title: 'My Analytics',
                          subtitle: 'View progress & performance',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AnalyticsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Class',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Class 10 (CBSE)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Locked',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildDivider(),
                        _buildTile(
                          icon: Icons.person_rounded,
                          iconColor: AppColors.sstPrimary,
                          title: 'Edit Profile',
                          subtitle: 'Name, class, preferences',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _showEditNameDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ═══ PREFERENCES ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Preferences', style: AppTextStyles.caption),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_rounded,
                          iconColor: AppColors.warning,
                          title: 'Notifications',
                          subtitle: 'Daily reminders & streaks',
                          value: _notificationsEnabled,
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            setState(() => _notificationsEnabled = v);
                          },
                        ),
                        _buildDivider(),
                        _buildSwitchTile(
                          icon: Icons.volume_up_rounded,
                          iconColor: AppColors.hindiPrimary,
                          title: 'Sound Effects',
                          subtitle: 'Quiz & interaction sounds',
                          value: _soundEnabled,
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            setState(() => _soundEnabled = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ═══ SUPPORT & INFO ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('Support', style: AppTextStyles.caption),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildTile(
                          icon: Icons.card_giftcard_rounded,
                          iconColor: AppColors.warning,
                          title: 'Refer & Earn',
                          subtitle: 'Get 200 XP for each friend',
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReferEarnScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildTile(
                          icon: Icons.privacy_tip_outlined,
                          iconColor: AppColors.textMuted,
                          title: 'Privacy Policy',
                          subtitle: 'How we handle your data',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LegalScreen(
                                  document: LegalDocument.privacy,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildTile(
                          icon: Icons.description_outlined,
                          iconColor: AppColors.textMuted,
                          title: 'Terms & Conditions',
                          subtitle: 'Rules for using DecaGrade',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LegalScreen(
                                  document: LegalDocument.terms,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // ═══ DANGER ZONE ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Logout button
                      DuolingoButton(
                        label: 'LOGOUT',
                        color: AppColors.error,
                        darkColor: const Color(0xFFB91C1C),
                        icon: Icons.logout_rounded,
                        width: double.infinity,
                        height: 50,
                        fontSize: 13,
                        onPressed: _handleLogout,
                      ),

                      const SizedBox(height: 12),

                      // Delete account
                      GestureDetector(
                        onTap: _handleDeleteAccount,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            'Delete Account',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ═══ APP INFO ═══
              SliverToBoxAdapter(
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradientHero,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'DecaGrade',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text('Version 1.0.0', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 8),
                      Text(
                        'Made with 💙 in India',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: iconColor,
            activeTrackColor: iconColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.border,
    );
  }
}
