import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/duolingo_button.dart';
import '../../services/analytics_service.dart';
import '../../widgets/mascots/svg_mascot.dart';

class DailyQuizScreen extends StatefulWidget {
  const DailyQuizScreen({super.key});

  @override
  State<DailyQuizScreen> createState() => _DailyQuizScreenState();
}

class _DailyQuizScreenState extends State<DailyQuizScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, dynamic>? _quiz;
  bool _isLoading = true;
  bool _hasCompleted = false;
  bool _quizStarted = false;
  int _dailyStreak = 0;
  List<Map<String, dynamic>> _history = [];

  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _hasAnswered = false;
  int _score = 0;
  DateTime? _startTime;
  bool _isComplete = false;
  int _totalXpEarned = 0;

  Timer? _countdownTimer;
  Duration _timeUntilTomorrow = Duration.zero;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _loadData();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    setState(() {
      _timeUntilTomorrow = tomorrow.difference(now);
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _firestoreService.getTodayDailyQuiz(),
      _firestoreService.hasCompletedTodayQuiz(),
      _firestoreService.getDailyQuizStreak(),
      _firestoreService.getDailyQuizHistory(),
    ]);

    if (mounted) {
      setState(() {
        _quiz = results[0] as Map<String, dynamic>?;
        _hasCompleted = results[1] == true;
        _dailyStreak = (results[2] as num?)?.toInt() ?? 0;
        _history = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  void _startQuiz() {
    HapticFeedback.mediumImpact();
    setState(() {
      _quizStarted = true;
      _startTime = DateTime.now();
    });
  }

  void _selectAnswer(int index) {
    if (_hasAnswered) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedAnswer = index);
  }

  void _submitAnswer() {
    if (_selectedAnswer == null || _hasAnswered) return;

    final questions = (_quiz!['questions'] as List);
    final currentQ = questions[_currentIndex] as Map<String, dynamic>;
    final correctAnswer = currentQ['correctAnswer'];
    final isCorrect = _selectedAnswer == correctAnswer;

    if (isCorrect) {
      HapticFeedback.heavyImpact();
      setState(() => _score++);
    } else {
      HapticFeedback.vibrate();
    }

    setState(() => _hasAnswered = true);
  }

  Future<void> _nextQuestion() async {
    HapticFeedback.lightImpact();
    final questions = (_quiz!['questions'] as List);

    if (_currentIndex < questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
      });
    } else {
      final timeSpent = DateTime.now().difference(_startTime!).inSeconds;

      await _firestoreService.saveDailyQuizResult(
        score: _score,
        totalQuestions: questions.length,
        timeSpent: timeSpent,
      );
      unawaited(
        AnalyticsService.instance.logQuizCompleted(
          score: _score,
          totalQuestions: questions.length,
        ),
      );

      if (mounted) {
        setState(() {
          _isComplete = true;
          _totalXpEarned = 50 + (_score * 10);
        });

        _confettiController.play();
        HapticFeedback.heavyImpact();
      }
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
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

    if (_isComplete) {
      return _buildCompletionScreen();
    }

    if (_quizStarted && _quiz != null) {
      return _buildQuizScreen();
    }

    return _buildIntroScreen();
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildStreakCard(),
                const SizedBox(height: 16),
                if (_hasCompleted)
                  _buildAlreadyCompletedCard()
                else if (_quiz == null)
                  _buildNoQuizCard()
                else
                  _buildQuizPreviewCard(),
                const SizedBox(height: 16),
                if (_history.isNotEmpty) _buildHistorySection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
            const Icon(Icons.bolt_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: 6),
            Text('Daily Quiz', style: AppTextStyles.heading2),
          ],
        ),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_dailyStreak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'day streak',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Text(
                  _dailyStreak == 0
                      ? 'Start your streak today!'
                      : _dailyStreak < 7
                      ? 'Keep it going!'
                      : _dailyStreak < 30
                      ? 'You\'re on fire!'
                      : 'INCREDIBLE! 🏆',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildAlreadyCompletedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SvgMascot(type: MascotType.aria, size: 100, animate: true),
          const SizedBox(height: 12),
          const Text(
            '✅ Already Done!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You completed today\'s quiz!\nCome back tomorrow.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  '⏱️ Next quiz in',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_timeUntilTomorrow),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildNoQuizCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          const SvgMascot(type: MascotType.aria, size: 100, animate: true),
          const SizedBox(height: 12),
          Text('No quiz today!', style: AppTextStyles.heading1),
          const SizedBox(height: 8),
          Text(
            'Check back later or contact admin to add today\'s quiz.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizPreviewCard() {
    final questions = (_quiz!['questions'] as List);
    final xpReward = _quiz!['xpReward'] ?? 50;
    final topic = _quiz!['topic'] ?? 'Mixed Topics';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientHero),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.large,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'TODAY\'S CHALLENGE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('⚡', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 12),
          Text(
            topic,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuizInfo('📝', '${questions.length}', 'Questions'),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildQuizInfo('⚡', '$xpReward+', 'Bonus XP'),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildQuizInfo('⏱️', '~2', 'Minutes'),
            ],
          ),
          const SizedBox(height: 24),
          DuolingoButton(
            label: 'START CHALLENGE 🚀',
            color: Colors.white,
            darkColor: const Color(0xFFE5E7EB),
            textColor: AppColors.primary,
            icon: Icons.play_arrow_rounded,
            width: double.infinity,
            height: 56,
            fontSize: 14,
            onPressed: _startQuiz,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2);
  }

  Widget _buildQuizInfo(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Recent Challenges', style: AppTextStyles.heading3),
          ],
        ),
        const SizedBox(height: 12),
        ...(_history.take(5).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final score = item['score'] ?? 0;
          final total = item['totalQuestions'] ?? 0;
          final percentage = total > 0 ? (score / total * 100) : 0.0;
          final xp = item['xpEarned'] ?? 0;
          final date = item['id'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: percentage >= 80
                        ? AppColors.success.withOpacity(0.15)
                        : percentage >= 60
                        ? AppColors.warning.withOpacity(0.15)
                        : AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${percentage.toInt()}%',
                    style: TextStyle(
                      color: percentage >= 80
                          ? AppColors.success
                          : percentage >= 60
                          ? AppColors.warning
                          : AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$score/$total correct',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 2),
                      Text(
                        '+$xp',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1);
        }).toList()),
      ],
    );
  }

  Widget _buildQuizScreen() {
    final questions = (_quiz!['questions'] as List);
    final currentQ = questions[_currentIndex] as Map<String, dynamic>;
    final progress = (_currentIndex + 1) / questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Exit Quiz?'),
                          content: const Text('Your progress will be lost.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Continue'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Exit'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '${_score * 10}',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Q ${_currentIndex + 1}/${questions.length}',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'DAILY CHALLENGE ⚡',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppShadows.small,
                          ),
                          child: Text(
                            currentQ['question'] ?? '',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                            ),
                          ),
                        )
                        .animate(key: ValueKey(_currentIndex))
                        .fadeIn()
                        .slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    ...(currentQ['options'] as List).asMap().entries.map((
                      entry,
                    ) {
                      final index = entry.key;
                      final option = entry.value;
                      final isSelected = _selectedAnswer == index;
                      final isCorrect = index == currentQ['correctAnswer'];
                      final showResult = _hasAnswered;

                      Color bgColor = AppColors.cardBg;
                      Color borderColor = AppColors.border;
                      Color textColor = AppColors.textPrimary;

                      if (showResult) {
                        if (isCorrect) {
                          bgColor = AppColors.success.withOpacity(0.15);
                          borderColor = AppColors.success;
                          textColor = AppColors.success;
                        } else if (isSelected) {
                          bgColor = AppColors.error.withOpacity(0.15);
                          borderColor = AppColors.error;
                          textColor = AppColors.error;
                        }
                      } else if (isSelected) {
                        bgColor = AppColors.primary.withOpacity(0.15);
                        borderColor = AppColors.primary;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => _selectAnswer(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected || (showResult && isCorrect)
                                        ? borderColor
                                        : AppColors.border,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index),
                                      style: TextStyle(
                                        color:
                                            isSelected ||
                                                (showResult && isCorrect)
                                            ? Colors.white
                                            : AppColors.textMuted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    if (_hasAnswered) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _selectedAnswer == currentQ['correctAnswer']
                              ? AppColors.success.withOpacity(0.1)
                              : AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedAnswer == currentQ['correctAnswer']
                                ? AppColors.success
                                : AppColors.error,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _selectedAnswer == currentQ['correctAnswer']
                                  ? Icons.check_circle_rounded
                                  : Icons.info_rounded,
                              color:
                                  _selectedAnswer == currentQ['correctAnswer']
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedAnswer == currentQ['correctAnswer']
                                        ? 'Correct! 🎉'
                                        : 'Not quite!',
                                    style: TextStyle(
                                      color:
                                          _selectedAnswer ==
                                              currentQ['correctAnswer']
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentQ['explanation'] ?? '',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.2),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: _hasAnswered
                    ? DuolingoButton(
                        label: _currentIndex < questions.length - 1
                            ? 'NEXT QUESTION'
                            : 'FINISH QUIZ 🏆',
                        color: AppColors.primary,
                        darkColor: AppColors.primaryDark,
                        icon: Icons.arrow_forward_rounded,
                        height: 54,
                        onPressed: _nextQuestion,
                      )
                    : DuolingoButton(
                        label: 'CHECK ANSWER',
                        color: _selectedAnswer != null
                            ? AppColors.primary
                            : AppColors.textMuted,
                        darkColor: _selectedAnswer != null
                            ? AppColors.primaryDark
                            : AppColors.textMuted,
                        icon: Icons.check_rounded,
                        height: 54,
                        onPressed: _selectedAnswer != null
                            ? _submitAnswer
                            : null,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final questions = (_quiz!['questions'] as List);
    final percentage = (_score / questions.length * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),

                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.3, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: SvgMascot(
                      type: MascotType.aria,
                      size: 160,
                      animate: true,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    percentage == 100
                        ? 'PERFECT! 🏆'
                        : percentage >= 80
                        ? 'AMAZING! 🌟'
                        : percentage >= 60
                        ? 'GOOD JOB! 👏'
                        : 'KEEP LEARNING! 💪',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

                  const SizedBox(height: 8),

                  Text(
                    'Daily challenge complete!',
                    style: AppTextStyles.bodyMedium,
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.gradientHero,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadows.large,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_score / ${questions.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 60,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '$percentage% Accuracy',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⚡', style: TextStyle(fontSize: 24)),
                              const SizedBox(width: 8),
                              Text(
                                '+$_totalXpEarned XP',
                                style: TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),

                  const Spacer(),

                  DuolingoButton(
                    label: 'AWESOME!',
                    color: AppColors.primary,
                    darkColor: AppColors.primaryDark,
                    icon: Icons.check_rounded,
                    width: double.infinity,
                    height: 56,
                    fontSize: 15,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                    },
                  ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.3,
              colors: const [
                AppColors.primary,
                AppColors.aiPrimary,
                AppColors.warning,
                AppColors.success,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
