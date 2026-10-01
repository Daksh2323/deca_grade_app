import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../services/seed_service.dart';

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  final SeedService _seedService = SeedService();
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String _firebaseProjectId = '';
  final List<String> _logs = [];
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _isAuthenticated = FirebaseAuth.instance.currentUser != null;
    _firebaseProjectId = Firebase.app().options.projectId;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _isAuthenticated = user != null;
      });
    });
    _addLog('🔧 Seed screen connected to project: $_firebaseProjectId');
    _addLog('👤 Authenticated: ${_isAuthenticated ? 'yes' : 'no'}');
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _addLog(String msg) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)} → $msg');
    });
  }

  Future<void> _authenticateIfNeeded() async {
    if (FirebaseAuth.instance.currentUser != null) return;

    _addLog('🔑 Signing in anonymously for dev seed...');
    try {
      await FirebaseAuth.instance.signInAnonymously();
      _addLog('✅ Authenticated anonymously');
    } catch (e) {
      _addLog('❌ Anonymous auth failed: $e');
      rethrow;
    }
  }

  Future<void> _seedAll() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      await _authenticateIfNeeded();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;

    _addLog('🌱 Starting seed...');

    final result = await _seedService.seedAllData();
    if (!mounted) return;
    _addLog(result);

    setState(() => _isLoading = false);
    HapticFeedback.lightImpact();
  }

  Future<void> _seedSingle(String label, Future<void> Function() action) async {
    HapticFeedback.selectionClick();
    setState(() => _isLoading = true);

    try {
      await _authenticateIfNeeded();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;

    _addLog('⏳ Seeding $label...');

    try {
      await action();
      if (!mounted) return;
      _addLog('✅ $label done');
    } catch (e) {
      if (!mounted) return;
      _addLog('❌ $label failed: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          '🔧 Dev — Seed Data',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Warning
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Dev tool only. Populates Firestore with sample data. Project: $_firebaseProjectId',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Seed All Button
              _buildSeedButton(
                label: 'Seed All Data',
                icon: Icons.cloud_upload_rounded,
                gradient: AppColors.gradientBlue,
                onTap: _seedAll,
                isPrimary: true,
              ),
              const SizedBox(height: 12),

              // Individual seed buttons
              Row(
                children: [
                  Expanded(
                    child: _buildMiniButton(
                      'Badges',
                      Icons.workspace_premium_rounded,
                      () => _seedSingle('Badges', _seedService.seedBadges),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniButton(
                      'Subjects',
                      Icons.school_rounded,
                      () => _seedSingle('Subjects', _seedService.seedSubjects),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniButton(
                      'Chapters',
                      Icons.menu_book_rounded,
                      () => _seedSingle('Chapters', _seedService.seedChapters),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniButton(
                      'Quizzes',
                      Icons.quiz_rounded,
                      () => _seedSingle('Quizzes', _seedService.seedQuizzes),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniButton(
                      'Mock Tests',
                      Icons.assignment_rounded,
                      () =>
                          _seedSingle('Mock Tests', _seedService.seedMockTests),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniButton(
                      'Daily Quiz',
                      Icons.today_rounded,
                      () =>
                          _seedSingle('Daily Quiz', _seedService.seedDailyQuiz),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniButton(
                      'PYQs',
                      Icons.history_edu_rounded,
                      () => _seedSingle('PYQs', _seedService.seedPYQs),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniButton(
                      'Refresh',
                      Icons.refresh_rounded,
                      () => _seedAll(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Logs
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Logs',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _logs.isEmpty
                      ? const Center(
                          child: Text(
                            'No logs yet. Click a seed button.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                _logs[index],
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeedButton({
    required String label,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMiniButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
