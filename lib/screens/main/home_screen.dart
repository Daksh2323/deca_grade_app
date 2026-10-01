import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/home_header.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/subject_card.dart';
import '../../widgets/premium_status_listener.dart';
import 'daily_quiz_screen.dart';
import 'math_solver_screen.dart';
import 'subject_detail_screen.dart';
import 'streak_celebration_screen.dart';
import '../premium/checkout_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _user;
  List<Map<String, dynamic>> _subjects = [];
  Map<String, dynamic>? _lastChapter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _firestoreService.getCurrentUser(),
        _firestoreService.getSubjectsFromDB(),
        _firestoreService.getLastChapter(),
      ]);
      if (mounted) {
        setState(() {
          _user = results[0] as UserModel?;
          _subjects = results[1] as List<Map<String, dynamic>>;
          _lastChapter = results[2] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }

    if (mounted) unawaited(_updateStreakInBackground());
  }

  Future<void> _updateStreakInBackground() async {
    try {
      final result = await _firestoreService.updateStreak();
      if (result['success'] != true) return;

      final updatedUser = await _firestoreService.getCurrentUser();
      if (!mounted || updatedUser == null) return;

      setState(() => _user = updatedUser);
    } catch (_) {
      // A failed streak update should not interrupt the Home screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: _buildLoadingState()),
      );
    }

    final user = _user;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          backgroundColor: AppColors.cardBg,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(
                  userName: user?.name.split(' ').first ?? 'Student',
                  currentClass: user?.userClass ?? 'Class 10',
                  streakDays: user?.streak ?? 0,
                  xpPoints: user?.xp ?? 0,
                  onStreakTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => StreakCelebrationScreen(
                          streak: user?.streak ?? 0,
                          maxStreak: user?.maxStreak ?? 0,
                          isNewRecord:
                              (user?.streak ?? 0) >= (user?.maxStreak ?? 0),
                        ),
                      ),
                    );
                  },
                  onClassTap: _showClassSelector,
                  onPremiumTap: _openPremium,
                ),
                const SizedBox(height: 32),
                _buildPremiumBannerSection(),
                _buildQuickActions(),
                const SizedBox(height: 32),
                _buildExamCountdown(),
                const SizedBox(height: 32),
                if (_lastChapter != null) _buildContinueLearningCard(),
                if (_lastChapter != null) const SizedBox(height: 32),
                _buildSubjectsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: const [
          SkeletonLoader(height: 100),
          SizedBox(height: 16),
          SkeletonLoader(height: 150),
          SizedBox(height: 16),
          SkeletonLoader(height: 220),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: _openPremium,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D2B1F), Color(0xFF8A5A18)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.2),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD166),
              size: 34,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Go Pro',
                    style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Unlimited AI, premium PDFs, and no ads',
                    style: TextStyle(color: Color(0xFFFFE7B2), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFFFFD166),
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05);
  }

  Widget _buildExamCountdown() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('app_config')
          .doc('exam_schedule')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 92, child: LoadingWidget());
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() ?? <String, dynamic>{};
        if (data['is_active'] != true) return const SizedBox.shrink();

        final examValue = data['exam_date'];
        final examDate = examValue is Timestamp
            ? examValue.toDate()
            : examValue is DateTime
            ? examValue
            : null;
        if (examDate == null) return const SizedBox.shrink();

        final examName = data['exam_name']?.toString().trim();
        if (examName == null || examName.isEmpty) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();
        if (!examDate.isAfter(now)) {
          return _buildExamStatusCard('Exams Completed', examName, false);
        }

        final daysRemaining = (examDate.difference(now).inMinutes / (24 * 60))
            .ceil();
        return _buildExamStatusCard(
          '$examName in $daysRemaining ${daysRemaining == 1 ? 'day' : 'days'}',
          'Keep your preparation on track.',
          true,
        );
      },
    );
  }

  Widget _buildExamStatusCard(String title, String subtitle, bool isUpcoming) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isUpcoming ? AppColors.aiLightBg : AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUpcoming ? AppColors.aiBorder : AppColors.border,
        ),
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Icon(
            isUpcoming
                ? Icons.event_available_rounded
                : Icons.event_busy_rounded,
            color: isUpcoming ? AppColors.aiPrimary : AppColors.textMuted,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading3,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBannerSection() {
    // ⚡ OPTIMIZATION: Use PremiumStatusListener to scope StreamBuilder rebuilds
    // This prevents entire home screen from rebuilding when user doc changes
    return PremiumStatusListener(
      builder: (context, isPremium) {
        if (isPremium) return const SizedBox.shrink();
        return Column(
          children: [_buildPremiumBanner(), const SizedBox(height: 32)],
        );
      },
    );
  }

  void _openPremium() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    ).then((paymentSubmitted) {
      if (paymentSubmitted == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Payment submitted. Premium activates after verification.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            Text('Quick Start', style: AppTextStyles.heading1),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildBentoCard(
                title: 'Math Solver',
                subtitle: 'Scan & solve instantly',
                icon: Icons.camera_rounded,
                baseColor: AppColors.aiPrimary,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MathSolverScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBentoCard(
                title: 'Daily Quiz',
                subtitle: 'Earn 50 XP today',
                icon: Icons.extension_rounded,
                baseColor: AppColors.warning,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyQuizScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildBentoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color baseColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: baseColor.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: baseColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: baseColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearningCard() {
    final chapter = _lastChapter!;
    final progress = (chapter['progress'] ?? 0.0).toDouble().clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: AppShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Continue Learning', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            chapter['title']?.toString() ?? 'Recent chapter',
            style: AppTextStyles.heading2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            chapter['subject']?.toString() ?? 'Subject',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.08);
  }

  Widget _buildSubjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Your Subjects', style: AppTextStyles.heading1),
            const Spacer(),
            Text(
              '${_subjects.length} subjects',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _subjects.length,
          itemBuilder: (context, index) {
            final subject = _subjects[index];
            final subjectId = subject['id']?.toString() ?? '';
            final color = _subjectColor(subjectId);
            return SubjectCard(
              subjectId: subjectId,
              subjectName: subject['name']?.toString() ?? 'Subject',
              color: color,
              darkColor: color,
              lightBg: color.withValues(alpha: 0.08),
              border: color.withValues(alpha: 0.25),
              completedChapters: 0,
              totalChapters: subject['totalChapters'] ?? 0,
              index: index,
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubjectDetailScreen(
                      subjectId: subjectId,
                      subjectName: subject['name']?.toString() ?? 'Subject',
                      colors: {
                        'primary': color,
                        'dark': color,
                        'light': color.withValues(alpha: 0.08),
                        'border': color.withValues(alpha: 0.25),
                      },
                      mascotType: _getMascotType(subjectId),
                      totalChapters: subject['totalChapters'] ?? 0,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.08);
  }

  Color _subjectColor(String? id) {
    switch (id) {
      case 'math':
        return AppColors.mathPrimary;
      case 'science':
        return AppColors.sciencePrimary;
      case 'english':
        return AppColors.englishPrimary;
      case 'social':
        return AppColors.sstPrimary;
      case 'hindi':
        return AppColors.hindiPrimary;
      default:
        return AppColors.primary;
    }
  }

  MascotType _getMascotType(String subjectId) {
    switch (subjectId) {
      case 'math':
        return MascotType.calculo;
      case 'science':
        return MascotType.drSpark;
      case 'english':
        return MascotType.owly;
      case 'social':
        return MascotType.indy;
      case 'hindi':
        return MascotType.kavi;
      default:
        return MascotType.calculo;
    }
  }

  void _showClassSelector() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXL),
        ),
      ),
      builder: (context) => Padding(
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
            Text('Select Your Class', style: AppTextStyles.heading1),
            const SizedBox(height: 20),
            ...['Class 10', 'Class 11', 'Class 12'].map(
              (value) => ListTile(
                onTap: () async {
                  await _firestoreService.updateUser({'class': value});
                  if (mounted) {
                    Navigator.pop(this.context);
                    _loadData();
                  }
                },
                leading: const Icon(
                  Icons.school_rounded,
                  color: AppColors.primary,
                ),
                title: Text(value, style: AppTextStyles.heading3),
                trailing: _user?.userClass == value
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
