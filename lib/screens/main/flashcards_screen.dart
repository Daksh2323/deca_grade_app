import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:card_swiper/card_swiper.dart';
import '../../config/theme.dart';
import '../../widgets/mascots/svg_mascot.dart';
import '../../widgets/rich_markdown_view.dart';
import '../../widgets/duolingo_button.dart';

class FlashcardsScreen extends StatefulWidget {
  final List<dynamic> flashcards;
  final String chapterTitle;
  final Map<String, Color> colors;
  final MascotType mascotType;

  const FlashcardsScreen({
    super.key,
    required this.flashcards,
    required this.chapterTitle,
    required this.colors,
    required this.mascotType,
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final SwiperController _swiperController = SwiperController();
  final Map<int, FlipCardController> _flipControllers = {};

  int _currentIndex = 0;
  final Set<int> _knownCards = {};
  final Set<int> _reviewCards = {};
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.flashcards.length; i++) {
      _flipControllers[i] = FlipCardController();
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  void _markAsKnown() {
    HapticFeedback.mediumImpact();
    setState(() {
      _knownCards.add(_currentIndex);
      _reviewCards.remove(_currentIndex);
    });
    _nextCard();
  }

  void _markForReview() {
    HapticFeedback.selectionClick();
    setState(() {
      _reviewCards.add(_currentIndex);
      _knownCards.remove(_currentIndex);
    });
    _nextCard();
  }

  void _nextCard() {
    if (_currentIndex < widget.flashcards.length - 1) {
      _swiperController.next();
    } else {
      _showCompletionScreen();
    }
  }

  void _showCompletionScreen() {
    setState(() => _isComplete = true);
  }

  void _restart() {
    HapticFeedback.mediumImpact();
    setState(() {
      _currentIndex = 0;
      _knownCards.clear();
      _reviewCards.clear();
      _isComplete = false;
    });
    _swiperController.move(0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return _buildEmptyState();
    }

    if (_isComplete) {
      return _buildCompletionScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            const SizedBox(height: 20),
            Expanded(
              child: Swiper(
                controller: _swiperController,
                itemCount: widget.flashcards.length,
                itemBuilder: (context, index) {
                  return _buildFlipCard(index);
                },
                onIndexChanged: (index) {
                  setState(() => _currentIndex = index);
                  HapticFeedback.selectionClick();
                },
                loop: false,
                viewportFraction: 0.85,
                scale: 0.9,
                itemHeight: 400,
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 16),
            _buildInstruction(),
            const SizedBox(height: 20),
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
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.style_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Flashcards',
                          style: AppTextStyles.heading2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    widget.chapterTitle,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.colors['light'],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.colors['border']!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.style_rounded,
                  color: widget.colors['dark'],
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentIndex + 1}/${widget.flashcards.length}',
                  style: TextStyle(
                    color: widget.colors['dark'],
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = widget.flashcards.isEmpty
        ? 0.0
        : ((_currentIndex + 1) / widget.flashcards.length).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_knownCards.length} Known',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.replay_rounded,
                      color: AppColors.warning,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_reviewCards.length} Review',
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
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.colors['primary']!,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipCard(int index) {
    final card = widget.flashcards[index] as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: FlipCard(
        controller: _flipControllers[index]!,
        direction: FlipDirection.HORIZONTAL,
        speed: 500,
        onFlipDone: (isFlipped) {
          HapticFeedback.selectionClick();
        },
        front: _buildCardFront(card, index),
        back: _buildCardBack(card, index),
      ),
    );
  }

  Widget _buildCardFront(Map<String, dynamic> card, int index) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.colors['primary']!, widget.colors['dark']!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.colors['primary']!.withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'CARD ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.question_mark_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'QUESTION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  card['front'] ?? 'No question',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Tap to reveal answer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Map<String, dynamic> card, int index) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.colors['border']!, width: 3),
        boxShadow: [
          BoxShadow(
            color: widget.colors['primary']!.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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
                  'CARD ${index + 1}',
                  style: TextStyle(
                    color: widget.colors['dark'],
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ANSWER',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: RichMarkdownView(
                  content: card['back'] ?? 'No answer',
                  selectable: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: widget.colors['light'],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: widget.colors['dark'],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap to flip back',
                  style: TextStyle(
                    color: widget.colors['dark'],
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _markForReview,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warning, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.replay_rounded,
                      color: AppColors.warning,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review Later',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _markAsKnown,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.success.withOpacity(0.7),
                      width: 3,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'I Know This!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe_rounded, color: AppColors.textMuted, size: 14),
          const SizedBox(width: 6),
          Text(
            'Swipe to navigate • Tap to flip',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
                    onPressed: () => Navigator.pop(context),
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
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgMascot(
                        type: widget.mascotType,
                        size: 120,
                        animate: true,
                      ),
                      const SizedBox(height: 20),
                      const Text('🃏', style: TextStyle(fontSize: 60)),
                      const SizedBox(height: 16),
                      Text('No flashcards yet!', style: AppTextStyles.heading1),
                      const SizedBox(height: 8),
                      Text(
                        'Flashcards will appear here once admin adds them',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final accuracy = widget.flashcards.isEmpty
        ? 0
        : ((_knownCards.length / widget.flashcards.length) * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Transform.scale(
                scale: 1.0,
                child: SvgMascot(
                  type: widget.mascotType,
                  size: 150,
                  animate: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                accuracy == 100
                    ? 'PERFECT! 🏆'
                    : accuracy >= 80
                    ? 'AMAZING! 🌟'
                    : accuracy >= 60
                    ? 'GREAT JOB! 👏'
                    : 'KEEP LEARNING! 💪',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: widget.colors['primary'],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
              const SizedBox(height: 8),
              Text(
                'You completed all flashcards!',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.colors['primary']!, widget.colors['dark']!],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: widget.colors['primary']!.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      '$accuracy%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Confidence Score',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('✅', '${_knownCards.length}', 'Known'),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildStatItem(
                          '🔄',
                          '${_reviewCards.length}',
                          'To Review',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        _buildStatItem(
                          '📚',
                          '${widget.flashcards.length}',
                          'Total',
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: DuolingoButton(
                      label: 'RESTART',
                      color: widget.colors['primary']!,
                      darkColor: widget.colors['dark']!,
                      icon: Icons.refresh_rounded,
                      height: 56,
                      onPressed: _restart,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DuolingoButton(
                      label: 'DONE',
                      color: AppColors.success,
                      darkColor: const Color(0xFF047857),
                      icon: Icons.check_rounded,
                      height: 56,
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
