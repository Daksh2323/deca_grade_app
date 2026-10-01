import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/math_text.dart';
import '../../widgets/duolingo_button.dart';
import '../../services/analytics_service.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String chapterId;
  final String chapterTitle;
  final String subjectId;
  final Map<String, Color> colors;
  final MascotType mascotType;

  const QuizScreen({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
    required this.subjectId,
    required this.colors,
    required this.mascotType,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _hasAnswered = false;
  int _score = 0;
  bool _isLoading = true;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    unawaited(
      AnalyticsService.instance.logQuizStarted(
        subject: widget.subjectId,
        chapter: widget.chapterId,
      ),
    );
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final questions = await _firestoreService.getQuizQuestions(
      subjectId: widget.subjectId,
      chapterId: widget.chapterId,
    );
    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(int index) {
    if (_hasAnswered) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedAnswer = index);
  }

  void _submitAnswer() {
    if (_selectedAnswer == null || _hasAnswered) return;

    final correctAnswer = _questions[_currentIndex]['correctAnswer'];
    final isCorrect = _selectedAnswer == correctAnswer;

    if (isCorrect) {
      HapticFeedback.heavyImpact();
      setState(() => _score++);
    } else {
      HapticFeedback.vibrate();
    }

    setState(() => _hasAnswered = true);
  }

  void _nextQuestion() {
    HapticFeedback.lightImpact();
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    final timeSpent = DateTime.now().difference(_startTime!).inSeconds;

    await _firestoreService.saveQuizResult(
      chapterId: widget.chapterId,
      score: _score,
      totalQuestions: _questions.length,
      timeSpent: timeSpent,
    );
    unawaited(
      AnalyticsService.instance.logQuizCompleted(
        score: _score,
        totalQuestions: _questions.length,
      ),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          score: _score,
          totalQuestions: _questions.length,
          timeSpent: timeSpent,
          chapterTitle: widget.chapterTitle,
          colors: widget.colors,
          mascotType: widget.mascotType,
        ),
      ),
    );
  }

  void _exitQuiz() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Exit Quiz?', style: AppTextStyles.heading2),
        content: Text(
          'Your progress will be lost.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Quiz'),
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
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: widget.colors['primary']),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgMascot(type: widget.mascotType, size: 120),
                  const SizedBox(height: 20),
                  Text('No quiz available yet!', style: AppTextStyles.heading1),
                  const SizedBox(height: 8),
                  Text(
                    'No quiz questions are available for this chapter yet.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DuolingoButton(
                    label: 'GO BACK',
                    color: widget.colors['primary']!,
                    darkColor: widget.colors['dark']!,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _exitQuiz,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.colors['primary']!,
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
                      mainAxisSize: MainAxisSize.min,
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
                    'Question ${_currentIndex + 1} of ${_questions.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.chapterTitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.colors['primary'],
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Animate(
              child: SvgMascot(
                type: widget.mascotType,
                size: 100,
                animate: !_hasAnswered,
              ),
            ).scale(begin: const Offset(0.5, 0.5)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: AppShadows.small,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.colors['light'],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'QUESTION',
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.colors['dark'],
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    MathText(
                      question['question'] ?? '',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: (question['options'] as List).length,
                itemBuilder: (context, index) {
                  return _buildOption(
                    index: index,
                    text: (question['options'] as List)[index],
                    correctAnswer: question['correctAnswer'],
                  );
                },
              ),
            ),
            if (_hasAnswered)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _selectedAnswer == question['correctAnswer']
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedAnswer == question['correctAnswer']
                        ? AppColors.success
                        : AppColors.error,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _selectedAnswer == question['correctAnswer']
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      color: _selectedAnswer == question['correctAnswer']
                          ? AppColors.success
                          : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAnswer == question['correctAnswer']
                                ? 'Correct! 🎉'
                                : 'Not quite!',
                            style: TextStyle(
                              color:
                                  _selectedAnswer == question['correctAnswer']
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          MathText(
                            question['explanation'] ?? '',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.2),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: _hasAnswered
                    ? DuolingoButton(
                        label: _currentIndex < _questions.length - 1
                            ? 'NEXT QUESTION'
                            : 'FINISH QUIZ 🏆',
                        color: widget.colors['primary']!,
                        darkColor: widget.colors['dark']!,
                        icon: Icons.arrow_forward_rounded,
                        height: 54,
                        fontSize: 14,
                        onPressed: _nextQuestion,
                      )
                    : DuolingoButton(
                        label: 'CHECK ANSWER',
                        color: _selectedAnswer != null
                            ? widget.colors['primary']!
                            : AppColors.textMuted,
                        darkColor: _selectedAnswer != null
                            ? widget.colors['dark']!
                            : AppColors.textMuted,
                        icon: Icons.check_rounded,
                        height: 54,
                        fontSize: 14,
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

  Widget _buildOption({
    required int index,
    required String text,
    required int correctAnswer,
  }) {
    final isSelected = _selectedAnswer == index;
    final isCorrect = index == correctAnswer;
    final showResult = _hasAnswered;

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData? iconData;

    if (showResult) {
      if (isCorrect) {
        bgColor = AppColors.success.withOpacity(0.15);
        borderColor = AppColors.success;
        textColor = AppColors.success;
        iconData = Icons.check_circle_rounded;
      } else if (isSelected) {
        bgColor = AppColors.error.withOpacity(0.15);
        borderColor = AppColors.error;
        textColor = AppColors.error;
        iconData = Icons.cancel_rounded;
      } else {
        bgColor = AppColors.cardBg;
        borderColor = AppColors.border;
        textColor = AppColors.textMuted;
        iconData = null;
      }
    } else {
      if (isSelected) {
        bgColor = widget.colors['light']!;
        borderColor = widget.colors['primary']!;
        textColor = widget.colors['dark']!;
      } else {
        bgColor = AppColors.cardBg;
        borderColor = AppColors.border;
        textColor = AppColors.textPrimary;
      }
      iconData = null;
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
                  color: isSelected || (showResult && isCorrect)
                      ? borderColor
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      color: isSelected || (showResult && isCorrect)
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
                child: MathText(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
              if (iconData != null)
                Icon(iconData, color: borderColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
