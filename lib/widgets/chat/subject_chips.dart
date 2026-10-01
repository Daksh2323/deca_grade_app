import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class SubjectChips extends StatelessWidget {
  final String? selectedSubject;
  final Function(String?) onSubjectSelected;

  const SubjectChips({
    super.key,
    required this.selectedSubject,
    required this.onSubjectSelected,
  });

  final List<Map<String, dynamic>> subjects = const [
    {'id': null, 'name': 'All', 'emoji': '💬', 'color': Color(0xFF6366F1)},
    {'id': 'math', 'name': 'Math', 'emoji': '🔢', 'color': Color(0xFF8B5CF6)},
    {
      'id': 'science',
      'name': 'Science',
      'emoji': '🔬',
      'color': Color(0xFF10B981),
    },
    {
      'id': 'english',
      'name': 'English',
      'emoji': '📚',
      'color': Color(0xFFF59E0B),
    },
    {
      'id': 'social',
      'name': 'Social',
      'emoji': '🌍',
      'color': Color(0xFFEC4899),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final isSelected = selectedSubject == subject['id'];

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSubjectSelected(subject['id']);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? subject['color'] : AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? subject['color'] : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: subject['color'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(subject['emoji'], style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    subject['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
