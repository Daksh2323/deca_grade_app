import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/theme.dart';
import '../../services/gemini_service.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/rich_markdown_view.dart';

class MathSolverScreen extends StatefulWidget {
  const MathSolverScreen({super.key});

  @override
  State<MathSolverScreen> createState() => _MathSolverScreenState();
}

class _MathSolverScreenState extends State<MathSolverScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();

  File? _imageFile;
  String? _solution;
  String? _error;
  bool _isLoading = false;
  String _selectedSubject = 'Math';

  final List<Map<String, dynamic>> _subjects = [
    {'name': 'Math', 'icon': '🔢', 'color': const Color(0xFF8B5CF6)},
    {'name': 'Science', 'icon': '🔬', 'color': const Color(0xFF10B981)},
    {'name': 'English', 'icon': '📚', 'color': const Color(0xFFF59E0B)},
    {'name': 'Social', 'icon': '🌍', 'color': const Color(0xFFEC4899)},
    {'name': 'Hindi', 'icon': '📖', 'color': const Color(0xFF06B6D4)},
    {'name': 'Any', 'icon': '✨', 'color': const Color(0xFF6366F1)},
  ];

  final List<String> _history = [];

  Future<void> _pickImage(ImageSource source) async {
    HapticFeedback.mediumImpact();

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        setState(() {
          _imageFile = File(picked.path);
          _solution = null;
          _error = null;
        });
      }
    } catch (e) {
      _showError('Failed to pick image');
    }
  }

  Future<void> _solveImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
      _solution = null;
      _error = null;
    });

    HapticFeedback.mediumImpact();

    try {
      final bytes = await _imageFile!.readAsBytes();

      final solution = await _geminiService.solveFromImage(
        imageBytes: bytes,
        subject: _selectedSubject == 'Any' ? null : _selectedSubject,
      );

      if (!mounted) return;
      setState(() {
        _solution = solution;
        _history.insert(
          0,
          _selectedSubject == 'Any' ? 'Any subject' : _selectedSubject,
        );
        if (_history.length > 8) {
          _history.removeLast();
        }
        _isLoading = false;
      });

      HapticFeedback.heavyImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      HapticFeedback.vibrate();
    }
  }

  void _shareSolution() {
    if (_solution == null) return;
    HapticFeedback.selectionClick();
    Share.share(
      '🎓 Solved by DecaGrade AI:\n\n$_solution\n\n📚 Try DecaGrade - Your AI Study Buddy!',
      subject: 'DecaGrade AI Solution',
    );
  }

  void _copySolution() {
    if (_solution == null) return;
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: _solution!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _imageFile = null;
      _solution = null;
      _error = null;
      _isLoading = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImageSourcePicker() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
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
              Text('Get Photo From', style: AppTextStyles.heading1),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      subtitle: 'Take a photo',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      subtitle: 'Choose photo',
                      color: AppColors.aiPrimary,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_imageFile == null && _solution == null)
                      _buildWelcomeSection(),
                    if (_imageFile != null) _buildImagePreview(),
                    if (_solution == null && _imageFile != null && !_isLoading)
                      _buildSubjectSelector(),
                    if (_isLoading) _buildLoadingSection(),
                    if (_error != null) _buildErrorSection(),
                    if (_solution != null) _buildSolutionSection(),
                    if (_history.isNotEmpty) _buildHistory(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
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
              const Text('📸', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Text('AI Math Solver', style: AppTextStyles.heading2),
            ],
          ),
          const Spacer(),
          if (_imageFile != null)
            IconButton(
              onPressed: _resetAll,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.refresh_rounded, color: AppColors.error),
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        const SizedBox(height: 20),
        SvgMascot(type: MascotType.aria, size: 140, animate: true),
        const SizedBox(height: 20),
        Text('Snap. Solve. Learn! 🎯', style: AppTextStyles.displayMedium),
        const SizedBox(height: 8),
        Text(
          'Take a photo of ANY problem\nand I\'ll solve it step-by-step!',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildFeatureBadge('🔢', 'Math'),
            _buildFeatureBadge('🔬', 'Science'),
            _buildFeatureBadge('📚', 'English'),
            _buildFeatureBadge('🌍', 'Social'),
            _buildFeatureBadge('📖', 'Hindi'),
            _buildFeatureBadge('✨', 'Any Subject'),
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.aiLightBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.aiBorder),
          ),
          child: Column(
            children: [
              Text('How it works?', style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              _buildStepRow('1️⃣', 'Tap camera or gallery icon'),
              _buildStepRow('2️⃣', 'Capture/select clear image'),
              _buildStepRow('3️⃣', 'Select subject (optional)'),
              _buildStepRow('4️⃣', 'AI analyzes & solves it!'),
              _buildStepRow('5️⃣', 'Get step-by-step solution'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBadge(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(number, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.file(
              _imageFile!,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'IMAGE READY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelector() {
    return Container(
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
              const Icon(
                Icons.school_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Select Subject (Optional)', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _subjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                final isSelected = _selectedSubject == subject['name'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedSubject = subject['name'];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? subject['color']
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? subject['color'] : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          subject['icon'],
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subject['name'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.aiLightBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.aiBorder, width: 2),
      ),
      child: Column(
        children: [
          const SvgMascot(type: MascotType.aria, size: 100, animate: true),
          const SizedBox(height: 16),
          Text(
            'Air is analyzing...',
            style: AppTextStyles.heading2.copyWith(color: AppColors.aiDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Reading your problem carefully 🤔',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(
            color: AppColors.aiPrimary,
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text('Oops! Something went wrong', style: AppTextStyles.heading3),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Please try again',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          DuolingoButton(
            label: 'TRY AGAIN',
            color: AppColors.error,
            darkColor: const Color(0xFFB91C1C),
            icon: Icons.refresh_rounded,
            onPressed: _solveImage,
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.aiBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.aiPrimary.withOpacity(0.1),
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
              const SvgMascot(type: MascotType.aria, size: 40, animate: false),
              const SizedBox(width: 10),
              Text(
                'Air\'s Solution',
                style: AppTextStyles.heading2.copyWith(color: AppColors.aiDark),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _copySolution,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.aiLightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    color: AppColors.aiDark,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _shareSolution,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.aiLightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.share_rounded,
                    color: AppColors.aiDark,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichMarkdownView(
            content: _solution!,
            selectable: true,
            title: null,
            showCopyButton: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('History', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _history.map((item) => Chip(label: Text(item))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_imageFile == null) ...[
            Expanded(
              child: DuolingoButton(
                label: 'CAMERA',
                color: AppColors.primary,
                darkColor: AppColors.primaryDark,
                icon: Icons.camera_alt_rounded,
                height: 54,
                onPressed: () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DuolingoButton(
                label: 'GALLERY',
                color: AppColors.aiPrimary,
                darkColor: AppColors.aiDark,
                icon: Icons.photo_library_rounded,
                height: 54,
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ),
          ] else if (_solution == null && !_isLoading && _error == null) ...[
            Expanded(
              child: DuolingoButton(
                label: 'RETAKE',
                color: AppColors.textMuted,
                darkColor: AppColors.textSecondary,
                icon: Icons.refresh_rounded,
                height: 54,
                onPressed: _showImageSourcePicker,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: DuolingoButton(
                label: 'SOLVE WITH AI ✨',
                color: AppColors.aiPrimary,
                darkColor: AppColors.aiDark,
                icon: Icons.auto_awesome_rounded,
                height: 54,
                fontSize: 14,
                onPressed: _solveImage,
              ),
            ),
          ] else if (_solution != null) ...[
            Expanded(
              child: DuolingoButton(
                label: 'SOLVE ANOTHER',
                color: AppColors.primary,
                darkColor: AppColors.primaryDark,
                icon: Icons.add_a_photo_rounded,
                height: 54,
                onPressed: _resetAll,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
