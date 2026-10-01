import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class QuickPrompts extends StatelessWidget {
  final Function(String) onPromptSelected;

  const QuickPrompts({super.key, required this.onPromptSelected});

  final List<Map<String, String>> prompts = const [
    {'icon': '📐', 'text': 'Explain Pythagoras theorem'},
    {'icon': '⚡', 'text': 'What is Ohm\'s law?'},
    {'icon': '📖', 'text': 'Give me a poem summary'},
    {'icon': '🌏', 'text': 'Types of rocks?'},
    {'icon': '✍️', 'text': 'Explain Ras in Hindi'},
    {'icon': '🧪', 'text': 'Chemical bonding basics'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Try asking...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: prompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = prompts[index];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPromptSelected(prompt['text']!);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.aiLightBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.aiBorder, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          prompt['icon']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          prompt['text']!,
                          style: TextStyle(
                            color: AppColors.aiDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
}
