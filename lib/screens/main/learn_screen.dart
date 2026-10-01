import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/loading_widget.dart';
import 'subject_detail_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;
  String _selectedBoard = 'CBSE';
  String _selectedClass = 'Class 10';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    final subjects = await _firestoreService.getSubjectsFromDB();
    if (mounted) {
      setState(() {
        _subjects = subjects;
        _isLoading = false;
      });
    }
  }

  Map<String, Color> _getSubjectColors(String subjectId) {
    switch (subjectId) {
      case 'math':
        return {
          'primary': AppColors.mathPrimary,
          'dark': AppColors.mathDark,
          'light': AppColors.mathLightBg,
          'border': AppColors.mathBorder,
        };
      case 'science':
        return {
          'primary': AppColors.sciencePrimary,
          'dark': AppColors.scienceDark,
          'light': AppColors.scienceLightBg,
          'border': AppColors.scienceBorder,
        };
      case 'english':
        return {
          'primary': AppColors.englishPrimary,
          'dark': AppColors.englishDark,
          'light': AppColors.englishLightBg,
          'border': AppColors.englishBorder,
        };
      case 'social':
        return {
          'primary': AppColors.sstPrimary,
          'dark': AppColors.sstDark,
          'light': AppColors.sstLightBg,
          'border': AppColors.sstBorder,
        };
      case 'hindi':
        return {
          'primary': AppColors.hindiPrimary,
          'dark': AppColors.hindiDark,
          'light': AppColors.hindiLightBg,
          'border': AppColors.hindiBorder,
        };
      default:
        return {
          'primary': AppColors.primary,
          'dark': AppColors.primaryDark,
          'light': AppColors.backgroundSecondary,
          'border': AppColors.borderMedium,
        };
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: true,
        child: RefreshIndicator(
          onRefresh: _loadSubjects,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ═══ HEADER ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text('Learn', style: AppTextStyles.displayMedium),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _isSearching = !_isSearching;
                                if (!_isSearching) _searchController.clear();
                              });
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Icon(
                                _isSearching
                                    ? Icons.close_rounded
                                    : Icons.search_rounded,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isSearching) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search subjects or topics...',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'Master your syllabus one chapter at a time',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.1),
              ),

              // ═══ BOARD & CLASS SELECTORS ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFilterCard(
                          label: 'Board',
                          value: _selectedBoard,
                          icon: Icons.school_rounded,
                          color: AppColors.primary,
                          onTap: () => _showBoardSelector(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFilterCard(
                          label: 'Class',
                          value: _selectedClass,
                          icon: Icons.class_rounded,
                          color: AppColors.aiPrimary,
                          onTap: () => _showClassSelector(),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
              ),

              // ═══ SECTION TITLE ═══
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Builder(
                    builder: (context) {
                      final query = _searchController.text.toLowerCase().trim();
                      final displaySubjects = query.isEmpty
                          ? _subjects
                          : _subjects
                                .where(
                                  (s) => (s['name'] ?? '')
                                      .toString()
                                      .toLowerCase()
                                      .contains(query),
                                )
                                .toList();

                      return Row(
                        children: [
                          Text(
                            _isSearching ? 'Results' : 'All Subjects',
                            style: AppTextStyles.heading1,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.aiLightBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${displaySubjects.length} subject${displaySubjects.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                color: AppColors.aiDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ═══ SUBJECT LIST ═══
              _isLoading
                  ? const SliverFillRemaining(child: LoadingWidget())
                  : Builder(
                      builder: (context) {
                        final query = _searchController.text
                            .toLowerCase()
                            .trim();
                        final displaySubjects = query.isEmpty
                            ? _subjects
                            : _subjects
                                  .where(
                                    (s) => (s['name'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .contains(query),
                                  )
                                  .toList();

                        if (displaySubjects.isEmpty) {
                          return SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 64,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No subjects found',
                                    style: AppTextStyles.heading2,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try a different search term',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final subject = displaySubjects[index];
                              return _buildSubjectListItem(subject, index);
                            }, childCount: displaySubjects.length),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.expand_more_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectListItem(Map<String, dynamic> subject, int index) {
    final colors = _getSubjectColors(subject['id']);
    final totalChapters = subject['totalChapters'] ?? 0;
    const completedChapters = 0;
    final progress = totalChapters > 0
        ? completedChapters / totalChapters
        : 0.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectDetailScreen(
              subjectId: subject['id'],
              subjectName: subject['name'],
              colors: colors,
              mascotType: _getMascotType(subject['id']),
              totalChapters: totalChapters,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          border: Border.all(color: colors['border']!, width: 2),
          boxShadow: [
            BoxShadow(
              color: colors['primary']!.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mascot
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: colors['light'],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SvgMascot(type: _getMascotType(subject['id']), size: 60),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject['name'] ?? 'Subject',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject['description'] ??
                        '$totalChapters chapters available',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: colors['light'],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors['primary']!,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$completedChapters/$totalChapters',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: colors['primary'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors['light'],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: colors['primary'],
                size: 18,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (300 + (index * 100)).ms).slideX(begin: 0.2);
  }

  void _showBoardSelector() {
    _showBottomSheet(
      title: 'Select Board',
      items: ['CBSE', 'ICSE', 'State Board'],
      selected: _selectedBoard,
      onSelect: (v) => setState(() => _selectedBoard = v),
    );
  }

  void _showClassSelector() {
    _showBottomSheet(
      title: 'Select Class',
      items: ['Class 10', 'Class 11', 'Class 12'],
      selected: _selectedClass,
      onSelect: (v) => setState(() => _selectedClass = v),
    );
  }

  void _showBottomSheet({
    required String title,
    required List<String> items,
    required String selected,
    required Function(String) onSelect,
  }) {
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
            Text(title, style: AppTextStyles.heading1),
            const SizedBox(height: 16),
            ...items.map(
              (item) => ListTile(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(item);
                  Navigator.pop(context);
                },
                leading: Icon(
                  Icons.check_circle_rounded,
                  color: selected == item
                      ? AppColors.success
                      : AppColors.textMuted.withOpacity(0.3),
                ),
                title: Text(item, style: AppTextStyles.heading3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
