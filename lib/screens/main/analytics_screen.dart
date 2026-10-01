import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/loading_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _quizResults = [];
  Map<String, dynamic> _overallStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _firestoreService.getAllQuizResults(limit: 20),
      _firestoreService.getOverallStats(),
    ]);

    if (mounted) {
      setState(() {
        _quizResults = results[0] as List<Map<String, dynamic>>;
        _overallStats = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    }
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    return '${hours}h ${minutes % 60}m';
  }

  String _getGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    return 'D';
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const LoadingWidget()
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeader(),
                    _buildOverviewCards(),
                    if (_quizResults.isEmpty)
                      _buildEmptyState()
                    else ...[
                      _buildProgressChart(),
                      _buildRecentQuizzes(),
                      _buildInsights(),
                    ],
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
                const Icon(
                  Icons.insights_rounded,
                  color: AppColors.aiPrimary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text('Analytics', style: AppTextStyles.heading2),
              ],
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalQuizzes = _overallStats['totalQuizzes'] ?? 0;
    final avgScore = (_overallStats['averageScore'] as num?)?.toDouble() ?? 0.0;
    final bestScore = _overallStats['bestScore'] ?? 0;
    final totalTime = _overallStats['totalTime'] ?? 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Container(
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
                  const Icon(
                    Icons.track_changes_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${avgScore.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Text(
                    'Average Score',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getMotivationalMessage(avgScore),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '📝',
                    '$totalQuizzes',
                    'Quizzes Taken',
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    '🏆',
                    '$bestScore%',
                    'Best Score',
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    '⏱️',
                    _formatTime(totalTime),
                    'Total Time',
                    AppColors.aiPrimary,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  String _getMotivationalMessage(double avg) {
    if (avg >= 90) return '🌟 EXCELLENT WORK!';
    if (avg >= 80) return '🎯 GREAT JOB!';
    if (avg >= 70) return '👏 KEEP IT UP!';
    if (avg >= 60) return '💪 GOOD PROGRESS!';
    if (avg > 0) return '📚 KEEP LEARNING!';
    return '🚀 START TAKING QUIZZES!';
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    final chartData = _quizResults.take(10).toList().reversed.toList();

    if (chartData.length < 2) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('📈', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('Progress Trend', style: AppTextStyles.heading3),
                  const Spacer(),
                  Text(
                    'Last ${chartData.length} quizzes',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.border,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 25,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt() + 1}',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (chartData.length - 1).toDouble(),
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData.asMap().entries.map((entry) {
                          final result = entry.value;
                          final score = (result['score'] as num?)?.toInt() ?? 0;
                          final total =
                              (result['totalQuestions'] as num?)?.toInt() ?? 1;
                          final percentage = total > 0
                              ? (score / total * 100)
                              : 0.0;
                          return FlSpot(entry.key.toDouble(), percentage);
                        }).toList(),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: AppColors.gradientHero,
                        ),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: AppColors.primary,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.3),
                              AppColors.primary.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
      ),
    );
  }

  Widget _buildRecentQuizzes() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📚', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text('Recent Quizzes', style: AppTextStyles.heading3),
                const Spacer(),
                Text(
                  '${_quizResults.length} total',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...(_quizResults.take(10).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final quiz = entry.value;
              return _buildQuizResultCard(quiz, index);
            }).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizResultCard(Map<String, dynamic> quiz, int index) {
    final score = (quiz['score'] as num?)?.toInt() ?? 0;
    final total = (quiz['totalQuestions'] as num?)?.toInt() ?? 0;
    final percentage = total > 0 ? (score / total * 100) : 0.0;
    final timeSpent = (quiz['timeSpent'] as num?)?.toInt() ?? 0;
    final chapterId = quiz['chapterId'] ?? 'Unknown';
    final completedAt = quiz['completedAt']?.toDate();

    final gradeColor = _getGradeColor(percentage);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: AppShadows.small,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradeColor, gradeColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradeColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getGrade(percentage),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapterId
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((word) {
                        return word.isNotEmpty
                            ? word[0].toUpperCase() + word.substring(1)
                            : '';
                      })
                      .join(' '),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$score/$total',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.timer_outlined,
                      color: AppColors.textMuted,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatTime(timeSpent),
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (completedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, h:mm a').format(completedAt),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${percentage.toInt()}%',
                style: TextStyle(
                  color: gradeColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  percentage >= 80
                      ? 'GREAT'
                      : percentage >= 60
                      ? 'GOOD'
                      : 'PRACTICE',
                  style: TextStyle(
                    color: gradeColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.1);
  }

  Widget _buildInsights() {
    final avg = (_overallStats['averageScore'] as num?)?.toDouble() ?? 0.0;
    final totalQuizzes = _overallStats['totalQuizzes'] ?? 0;

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
                color: AppColors.aiPrimary.withOpacity(0.3),
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
                    'Air\'s Insights 💡',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInsightItem(
                totalQuizzes < 5
                    ? '📝 Take more quizzes to see detailed insights!'
                    : avg >= 80
                    ? '🌟 You\'re performing excellently! Keep it up!'
                    : avg >= 60
                    ? '💪 Solid progress! Focus on weak areas.'
                    : '📚 Practice more to improve your scores.',
              ),
              if (totalQuizzes >= 3)
                _buildInsightItem(
                  '🎯 You\'ve completed $totalQuizzes quizzes so far',
                ),
              _buildInsightItem(
                avg >= 70
                    ? '🚀 Try harder chapters to challenge yourself'
                    : '📖 Review notes before taking quizzes',
              ),
            ],
          ),
        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
      ),
    );
  }

  Widget _buildInsightItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SvgMascot(type: MascotType.aria, size: 140, animate: true),
              const SizedBox(height: 20),
              const Text('📊', style: TextStyle(fontSize: 50)),
              const SizedBox(height: 12),
              Text('No quizzes yet!', style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              Text(
                'Take your first quiz to see\ndetailed analytics and progress',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
