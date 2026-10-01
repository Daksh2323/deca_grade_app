import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/mascots/svg_mascot.dart';
import 'qpg_loading_screen.dart';

class QpgSetupScreen extends StatefulWidget {
  const QpgSetupScreen({super.key});

  @override
  State<QpgSetupScreen> createState() => _QpgSetupScreenState();
}

class _QpgSetupScreenState extends State<QpgSetupScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;

  List<Map<String, dynamic>> _subjects = [];
  String? _selectedSubjectId;
  String? _selectedSubjectName;

  List<Map<String, dynamic>> _chapters = [];
  final List<String> _selectedChapters = [];

  final _schoolController = TextEditingController(
    text: 'KENDRIYA VIDYALAYA SANGATHAN',
  );
  final _examController = TextEditingController(text: 'MID-TERM EXAMINATION');

  int _mcqCount = 5;
  int _arCount = 1;
  int _twoMarkCount = 3;
  int _threeMarkCount = 2;
  int _fiveMarkCount = 1;
  int _caseCount = 1;

  int get _totalMarks =>
      (_mcqCount * 1) +
      (_arCount * 1) +
      (_twoMarkCount * 2) +
      (_threeMarkCount * 3) +
      (_fiveMarkCount * 5) +
      (_caseCount * 4);
  int get _totalQuestions =>
      _mcqCount +
      _arCount +
      _twoMarkCount +
      _threeMarkCount +
      _fiveMarkCount +
      _caseCount;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _schoolController.dispose();
    _examController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final subjects = await _firestoreService.getSubjectsFromDB();
    if (!mounted) return;
    setState(() {
      _subjects = subjects;
      _isLoading = false;
    });
  }

  Future<void> _loadChapters(String subjectId, String name) async {
    setState(() {
      _isLoading = true;
      _selectedSubjectId = subjectId;
      _selectedSubjectName = name;
      _selectedChapters.clear();
    });

    final chapters = await _firestoreService.getChapters(subjectId: subjectId);

    if (!mounted) return;

    if (chapters.isNotEmpty) {
      setState(() {
        _chapters = chapters;
        _isLoading = false;
      });
    } else {
      final fallbackChapters = _getFallbackNcertChapters(subjectId);
      setState(() {
        _chapters = fallbackChapters;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFallbackNcertChapters(String subjectId) {
    final catalog = {
      'math': [
        {'id': 'ch1', 'title': 'Real Numbers'},
        {'id': 'ch2', 'title': 'Polynomials'},
        {'id': 'ch3', 'title': 'Linear Equations'},
        {'id': 'ch4', 'title': 'Quadratic Equations'},
        {'id': 'ch5', 'title': 'Arithmetic Progressions'},
      ],
      'science': [
        {'id': 'ch1', 'title': 'Chemical Reactions'},
        {'id': 'ch2', 'title': 'Acids, Bases, Salts'},
        {'id': 'ch3', 'title': 'Metals & Non-Metals'},
        {'id': 'ch4', 'title': 'Carbon Compounds'},
      ],
    };
    return (catalog[subjectId] ?? catalog['math']!)
        .map((e) => {'id': e['id'], 'title': e['title']})
        .toList();
  }

  void _applyPreset(String preset) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (preset == 'board80') {
        _mcqCount = 16;
        _arCount = 4;
        _twoMarkCount = 5;
        _threeMarkCount = 6;
        _fiveMarkCount = 4;
        _caseCount = 3;
      } else if (preset == 'mid40') {
        _mcqCount = 8;
        _arCount = 2;
        _twoMarkCount = 3;
        _threeMarkCount = 3;
        _fiveMarkCount = 1;
        _caseCount = 1;
      } else if (preset == 'quick20') {
        _mcqCount = 5;
        _arCount = 1;
        _twoMarkCount = 2;
        _threeMarkCount = 2;
        _fiveMarkCount = 0;
        _caseCount = 0;
      }
    });
  }

  void _generate() {
    if (_selectedSubjectId == null || _selectedChapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a subject and at least 1 chapter.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_totalQuestions == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least 1 question to the blueprint.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    List<String> selectedChapterNames = _chapters
        .where((c) => _selectedChapters.contains(c['id']))
        .map((c) => c['title']?.toString() ?? '')
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QpgLoadingScreen(
          subject: _selectedSubjectName!,
          subjectId: _selectedSubjectId!,
          chapters: selectedChapterNames,
          schoolName: _schoolController.text.trim(),
          examName: _examController.text.trim(),
          mcqCount: _mcqCount,
          arCount: _arCount,
          twoMarkCount: _twoMarkCount,
          threeMarkCount: _threeMarkCount,
          fiveMarkCount: _fiveMarkCount,
          caseCount: _caseCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: true,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroBanner(),
                          const SizedBox(height: 24),

                          _buildSectionTitle(
                            '1',
                            'Paper Details',
                            Icons.edit_document,
                          ),
                          _buildTextField(
                            'Institution Name',
                            _schoolController,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField('Examination Name', _examController),
                          const SizedBox(height: 32),

                          _buildSectionTitle(
                            '2',
                            'Select Subject',
                            Icons.school_rounded,
                          ),
                          _buildSubjectSelector(),
                          const SizedBox(height: 32),

                          if (_selectedSubjectId != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionTitle(
                                  '3',
                                  'Chapters',
                                  Icons.library_books_rounded,
                                ),
                                TextButton(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (_selectedChapters.length ==
                                          _chapters.length) {
                                        _selectedChapters.clear();
                                      } else {
                                        _selectedChapters.addAll(
                                          _chapters.map(
                                            (e) => e['id'].toString(),
                                          ),
                                        );
                                      }
                                    });
                                  },
                                  child: Text(
                                    _selectedChapters.length == _chapters.length
                                        ? 'Deselect All'
                                        : 'Select All',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _buildChapterGrid(),
                            const SizedBox(height: 32),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionTitle(
                                  '4',
                                  'Blueprint',
                                  Icons.architecture_rounded,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Total: $_totalMarks Marks',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildPresets(),
                            const SizedBox(height: 16),
                            _buildBlueprintConfigurator(),
                            const SizedBox(height: 40),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: DuolingoButton(
                      label: 'GENERATE PAPER ✨',
                      color: AppColors.primary,
                      darkColor: AppColors.primaryDark,
                      height: 54,
                      width: double.infinity,
                      onPressed: _generate,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Exam Builder',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.medium,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 70,
            height: 70,
            child: SvgMascot(type: MascotType.aria, size: 70, animate: true),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Paper Generator',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Design perfect CBSE mock tests in seconds.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildSectionTitle(String number, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectSelector() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _subjects.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final sub = _subjects[index];
          final isSel = _selectedSubjectId == sub['id'];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _loadChapters(sub['id'], sub['name']);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 90,
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSel ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(sub['icon'], style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 6),
                  Text(
                    sub['name'],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSel ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildChapterGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.5,
      ),
      itemCount: _chapters.length,
      itemBuilder: (context, index) {
        final ch = _chapters[index];
        final isSel = _selectedChapters.contains(ch['id']);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isSel) {
                _selectedChapters.remove(ch['id']);
              } else {
                _selectedChapters.add(ch['id']);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSel
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSel ? AppColors.primary : AppColors.border,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSel ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: isSel ? AppColors.primary : AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ch['title'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: isSel
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildPresets() {
    return Row(
      children: [
        Expanded(
          child: _buildPresetCard(
            '80 M',
            'Board Pattern',
            'board80',
            AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPresetCard(
            '40 M',
            'Mid-Term',
            'mid40',
            AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPresetCard(
            '20 M',
            'Quick Test',
            'quick20',
            AppColors.aiPrimary,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildPresetCard(String title, String sub, String key, Color color) {
    return GestureDetector(
      onTap: () => _applyPreset(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueprintConfigurator() {
    return Column(
      children: [
        _buildCounterRow(
          'Section A',
          'MCQs',
          '1M',
          _mcqCount,
          () => setState(() => _mcqCount--),
          () => setState(() => _mcqCount++),
        ),
        _buildCounterRow(
          'Section A',
          'A-R',
          '1M',
          _arCount,
          () => setState(() => _arCount--),
          () => setState(() => _arCount++),
        ),
        _buildCounterRow(
          'Section B',
          'Short I',
          '2M',
          _twoMarkCount,
          () => setState(() => _twoMarkCount--),
          () => setState(() => _twoMarkCount++),
        ),
        _buildCounterRow(
          'Section C',
          'Short II',
          '3M',
          _threeMarkCount,
          () => setState(() => _threeMarkCount--),
          () => setState(() => _threeMarkCount++),
        ),
        _buildCounterRow(
          'Section D',
          'Long',
          '5M',
          _fiveMarkCount,
          () => setState(() => _fiveMarkCount--),
          () => setState(() => _fiveMarkCount++),
        ),
        _buildCounterRow(
          'Section E',
          'Case Based',
          '4M',
          _caseCount,
          () => setState(() => _caseCount--),
          () => setState(() => _caseCount++),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildCounterRow(
    String section,
    String type,
    String marks,
    int value,
    VoidCallback onDec,
    VoidCallback onInc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              marks,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  section,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: value > 0
                    ? () {
                        HapticFeedback.selectionClick();
                        onDec();
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: value > 0
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: value > 0 ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onInc();
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
