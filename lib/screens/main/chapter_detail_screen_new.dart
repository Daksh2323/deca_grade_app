import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/duolingo_button.dart';
import 'quiz_screen.dart';

class ChapterDetailScreen extends StatefulWidget {
  final Map<String, dynamic> chapter;
  final String subjectId;
  final String subjectName;
  final Map<String, Color> colors;
  final MascotType mascotType;

  const ChapterDetailScreen({
    super.key,
    required this.chapter,
    required this.subjectId,
    required this.subjectName,
    required this.colors,
    required this.mascotType,
  });

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getContentCount(String type) {
    final content = widget.chapter[type];
    if (content is List) return content.length;
    if (content is String && content.isNotEmpty) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // ═══ HEADER ═══
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: widget.colors['light'],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔖 Bookmarked!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bookmark_outline_rounded,
                            color: widget.colors['primary'],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.colors['primary'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'CHAPTER ${widget.chapter['chapterNumber']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.chapter['title'] ?? 'Chapter',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.chapter['description'] ?? '',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),

            // ═══ TABS ═══
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.colors['primary']!, widget.colors['dark']!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                dividerColor: Colors.transparent,
                tabAlignment: TabAlignment.start,
                indicatorSize: TabBarIndicatorSize.tab,
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                onTap: (_) => HapticFeedback.selectionClick(),
                tabs: [
                  _buildTab(
                    'Notes',
                    _getContentCount('fullNotes') +
                        _getContentCount('shortNotes'),
                  ),
                  _buildTab('PDFs', _getContentCount('pdfs')),
                  _buildTab('Formulas', _getContentCount('formulas')),
                  _buildTab('Cards', _getContentCount('flashcards')),
                  _buildTab('NCERT', _getContentCount('ncertSolutions')),
                  _buildTab('PYQs', _getContentCount('pyqs')),
                ],
              ),
            ),

            // ═══ TAB CONTENT ═══
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotesTab(),
                  _buildPdfsTab(),
                  _buildFormulasTab(),
                  _buildFlashcardsTab(),
                  _buildNcertTab(),
                  _buildPyqTab(),
                ],
              ),
            ),

            // ═══ BOTTOM ACTION ═══
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DuolingoButton(
                      label: 'ASK AIR AI',
                      color: AppColors.aiPrimary,
                      darkColor: AppColors.aiDark,
                      icon: Icons.auto_awesome_rounded,
                      height: 50,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                        // Navigate to AI tutor tab
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DuolingoButton(
                      label: 'START QUIZ',
                      color: widget.colors['primary']!,
                      darkColor: widget.colors['dark']!,
                      icon: Icons.play_arrow_rounded,
                      height: 50,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizScreen(
                              chapterId: widget.chapter['id'],
                              chapterTitle: widget.chapter['title'],
                              subjectId: widget.subjectId,
                              colors: widget.colors,
                              mascotType: widget.mascotType,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTab() {
    final shortNotes = widget.chapter['shortNotes'] ?? '';
    final fullNotes = widget.chapter['fullNotes'] ?? '';

    if (shortNotes.isEmpty && fullNotes.isEmpty) {
      return _buildEmptyContent(
        Icons.menu_book_rounded,
        'No notes yet',
        'Notes will appear here once admin adds them',
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (shortNotes.isNotEmpty) ...[
          _buildNoteCard(
            title: 'Quick Summary',
            content: shortNotes,
            color: widget.colors['primary']!,
            lightBg: widget.colors['light']!,
          ),
          const SizedBox(height: 12),
        ],
        if (fullNotes.isNotEmpty)
          _buildNoteCard(
            title: 'Detailed Notes',
            content: fullNotes,
            color: AppColors.aiPrimary,
            lightBg: AppColors.aiLightBg,
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPdfsTab() {
    return _buildEmptyContent(
      Icons.picture_as_pdf_rounded,
      'No PDFs found in this section',
      'Firestore study_materials data will appear here once published',
    );
  }

  Widget _buildFormulasTab() {
    final formulas = (widget.chapter['formulas'] as List?) ?? [];

    if (formulas.isEmpty) {
      return _buildEmptyContent(
        Icons.functions_rounded,
        'No formulas yet',
        'Formula sheet will appear here',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: formulas.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.colors['light'],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.colors['border']!, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.colors['primary'],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectableText(
                  formulas[index],
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: formulas[index]));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Formula copied!'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Icon(
                  Icons.copy_rounded,
                  color: widget.colors['dark'],
                  size: 16,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.1);
      },
    );
  }

  Widget _buildFlashcardsTab() {
    final flashcards = (widget.chapter['flashcards'] as List?) ?? [];

    if (flashcards.isEmpty) {
      return _buildEmptyContent(
        Icons.style_rounded,
        'No flashcards yet',
        'Flashcards will appear here',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: flashcards.length,
      itemBuilder: (context, index) {
        final card = flashcards[index] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.colors['border']!, width: 1.5),
            boxShadow: AppShadows.small,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: widget.colors['primary'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Q ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.style_rounded,
                    color: widget.colors['primary'],
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                card['front'] ?? '',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.colors['light'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: widget.colors['dark'],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        card['back'] ?? '',
                        style: TextStyle(
                          color: widget.colors['dark'],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildNcertTab() {
    final solutions = (widget.chapter['ncertSolutions'] as List?) ?? [];

    if (solutions.isEmpty) {
      return _buildEmptyContent(
        Icons.menu_book_rounded,
        'No NCERT solutions yet',
        'Chapter solutions will appear here',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: solutions.length,
      itemBuilder: (context, index) {
        final sol = solutions[index] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: widget.colors['primary'],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Q ${sol['questionNumber'] ?? index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${sol['marks'] ?? 1} marks',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sol['question'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.colors['light'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: widget.colors['dark'],
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Solution:',
                          style: TextStyle(
                            color: widget.colors['dark'],
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sol['solution'] ?? '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildPyqTab() {
    final pyqs = (widget.chapter['pyqs'] as List?) ?? [];

    if (pyqs.isEmpty) {
      return _buildEmptyContent(
        Icons.article_rounded,
        'No PYQs yet',
        'Previous year questions will appear here',
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: pyqs.length,
      itemBuilder: (context, index) {
        final pyq = pyqs[index] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.aiPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${pyq['year'] ?? 2024}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${pyq['marks'] ?? 1} marks',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(
                        pyq['difficulty'] ?? 'medium',
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (pyq['difficulty'] ?? 'medium').toUpperCase(),
                      style: TextStyle(
                        color: _getDifficultyColor(
                          pyq['difficulty'] ?? 'medium',
                        ),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                pyq['question'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.colors['light'],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates_rounded,
                          color: widget.colors['dark'],
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Answer:',
                          style: TextStyle(
                            color: widget.colors['dark'],
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pyq['solution'] ?? '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1);
      },
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'hard':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Widget _buildNoteCard({
    required String title,
    required String content,
    required Color color,
    required Color lightBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: lightBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            content,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildEmptyContent(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgMascot(type: widget.mascotType, size: 100, animate: true),
            const SizedBox(height: 16),
            Icon(icon, color: AppColors.primary, size: 40),
            const SizedBox(height: 8),
            Text(title, style: AppTextStyles.heading2),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
