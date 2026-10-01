import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../services/analytics_service.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/duolingo_button.dart';
import 'chapter_detail_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final Map<String, Color> colors;
  final MascotType mascotType;
  final int totalChapters;

  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.colors,
    required this.mascotType,
    required this.totalChapters,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _chapters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() => _isLoading = true);
    final chapters = await _firestoreService.getChapters(
      subjectId: widget.subjectId,
    );
    if (mounted) {
      // Inject "General / Full Syllabus" at the top
      final examPrepChapter = {
        'id': 'general_full_syllabus',
        'title': '📝 Full Syllabus & Exam Prep',
        'description': 'Sample Papers, PYQs, and Question Banks',
        'chapterName':
            'General / Full Syllabus', // EXACT match for Firestore query
        'isSpecial': true, // Flag for special styling
        'chapterNumber': 0,
      };

      final realChapters = chapters
          .where(FirestoreService.isRealChapter)
          .toList();

      final displayChapters = [examPrepChapter, ...realChapters];

      setState(() {
        _chapters = displayChapters;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // ═══ HERO HEADER ═══
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: widget.colors['light'],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Top bar
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.school_rounded,
                              color: widget.colors['primary'],
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Class 10 • CBSE',
                              style: TextStyle(
                                color: widget.colors['primary'],
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mascot + Title
                  Row(
                    children: [
                      SvgMascot(type: widget.mascotType, size: 100),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subjectName,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  color: widget.colors['primary'],
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_chapters.where((chapter) => chapter['isSpecial'] != true).length} Chapters',
                                  style: TextStyle(
                                    color: widget.colors['dark'],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(),

            // ═══ CHAPTERS LIST ═══
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _chapters.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadChapters,
                      color: widget.colors['primary'],
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: _chapters.length,
                        itemBuilder: (context, index) {
                          return _buildChapterCard(_chapters[index], index);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgMascot(type: widget.mascotType, size: 120, animate: true),
            const SizedBox(height: 20),
            Text('No chapters yet!', style: AppTextStyles.heading1),
            const SizedBox(height: 8),
            Text(
              'Chapters not loaded from Firestore.\n\n'
              'Try:\n'
              '1. Go back to splash screen\n'
              '2. Long-press "Made with 💙 in India"\n'
              '3. Choose "Seed Data"\n'
              '4. Click "Chapters" button\n'
              '5. Come back here',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            DuolingoButton(
              label: 'REFRESH',
              color: widget.colors['primary']!,
              darkColor: widget.colors['dark']!,
              icon: Icons.refresh_rounded,
              onPressed: () {
                HapticFeedback.mediumImpact();
                _loadChapters();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter, int index) {
    final isSpecial = chapter['isSpecial'] == true;
    final chapterNum = chapter['chapterNumber'] ?? (index + 1);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        unawaited(
          AnalyticsService.instance.logViewChapter(
            subject: widget.subjectId,
            chapter: (chapter['id'] ?? chapter['chapterId'] ?? 'unknown').toString(),
          ),
        );

        if (isSpecial) {
          // Special handling for "General / Full Syllabus"
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChapterDetailScreen(
                chapter: {
                  'title': chapter['chapterName'], // 'General / Full Syllabus'
                  ...chapter,
                },
                subjectId: widget.subjectId,
                subjectName: widget.subjectName,
                colors: widget.colors,
                mascotType: widget.mascotType,
              ),
            ),
          );
        } else {
          // Normal chapter handling
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChapterDetailScreen(
                chapter: chapter,
                subjectId: widget.subjectId,
                subjectName: widget.subjectName,
                colors: widget.colors,
                mascotType: widget.mascotType,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSpecial ? widget.colors['light'] : AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(
            color: isSpecial ? widget.colors['primary']! : AppColors.border,
            width: isSpecial ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.colors['primary']!.withOpacity(
                isSpecial ? 0.15 : 0.06,
              ),
              blurRadius: isSpecial ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Chapter number badge or special icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isSpecial
                    ? LinearGradient(
                        colors: [
                          widget.colors['primary']!,
                          widget.colors['dark']!,
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          widget.colors['primary']!,
                          widget.colors['dark']!,
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: isSpecial
                    ? const Icon(
                        Icons.article_rounded,
                        color: Colors.white,
                        size: 24,
                      )
                    : Text(
                        '$chapterNum',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
                    chapter['title'] ?? 'Chapter',
                    style: TextStyle(
                      fontSize: isSpecial ? 16 : 15,
                      fontWeight: isSpecial ? FontWeight.w900 : FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chapter['description'] ?? 'Tap to explore',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isSpecial) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTag(
                          Icons.timer_outlined,
                          '${chapter['estimatedTime'] ?? 45} min',
                        ),
                        const SizedBox(width: 6),
                        _buildTag(
                          Icons.style_rounded,
                          '${(chapter['flashcards'] as List?)?.length ?? 0} cards',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: widget.colors['primary'],
              size: 24,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (200 + (index * 80)).ms).slideX(begin: 0.2);
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: widget.colors['light'],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: widget.colors['dark']),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: widget.colors['dark'],
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
