import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import 'mascots/svg_mascot.dart';

class SubjectCard extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final Color color;
  final Color darkColor;
  final Color lightBg;
  final Color border;
  final int completedChapters;
  final int totalChapters;
  final int index;
  final VoidCallback? onTap;

  const SubjectCard({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.color,
    required this.darkColor,
    required this.lightBg,
    required this.border,
    required this.completedChapters,
    required this.totalChapters,
    required this.index,
    this.onTap,
  });

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> {
  bool _isPressed = false;

  Widget _getMascot() {
    MascotType type;
    switch (widget.subjectId) {
      case 'math':
        type = MascotType.calculo;
        break;
      case 'science':
        type = MascotType.drSpark;
        break;
      case 'english':
        type = MascotType.owly;
        break;
      case 'social':
        type = MascotType.indy;
        break;
      case 'hindi':
        type = MascotType.kavi;
        break;
      default:
        type = MascotType.calculo;
    }
    return SvgMascot(type: type, size: 75);
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalChapters > 0
        ? widget.completedChapters / widget.totalChapters
        : 0.0;

    return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.selectionClick();
            widget.onTap?.call();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                border: Border.all(color: widget.border, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _getMascot(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subjectName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${widget.completedChapters}/${widget.totalChapters}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'chapters',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: widget.lightBg,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (400 + (widget.index * 100)).ms)
        .scale(begin: const Offset(0.8, 0.8));
  }
}
