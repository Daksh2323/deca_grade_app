import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

import '../config/theme.dart';
import '../utils/toast_helper.dart';

class RichMarkdownView extends StatelessWidget {
  final String content;
  final bool selectable;
  final String? title;
  final EdgeInsetsGeometry? padding;
  final bool showCopyButton;

  const RichMarkdownView({
    super.key,
    required this.content,
    this.selectable = true,
    this.title,
    this.padding,
    this.showCopyButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final formulas = _extractFormulaBlocks(content);
    final markdownBody = _stripFormulaBlocks(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: AppTextStyles.heading3.copyWith(color: AppColors.aiDark),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(0),
          child: MarkdownBody(
            data: markdownBody,
            selectable: selectable,
            builders: {'math': FormulaElementBuilder()},
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
              h1: TextStyle(
                color: AppColors.aiDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
              h2: TextStyle(
                color: AppColors.aiDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              h3: TextStyle(
                color: AppColors.aiDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
              strong: TextStyle(
                color: AppColors.aiDark,
                fontWeight: FontWeight.w900,
              ),
              em: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              listBullet: TextStyle(
                color: AppColors.aiPrimary,
                fontWeight: FontWeight.w900,
              ),
              blockquote: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              code: TextStyle(
                backgroundColor: AppColors.aiLightBg,
                color: AppColors.aiDark,
                fontFamily: 'monospace',
              ),
              codeblockDecoration: BoxDecoration(
                color: AppColors.aiLightBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.aiBorder),
              ),
              blockSpacing: 12,
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
            ),
            onTapLink: (text, href, title) {
              // Links are left as plain markdown links in the current renderer.
            },
          ),
        ),
        if (formulas.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Formula Highlights',
            style: AppTextStyles.heading3.copyWith(color: AppColors.aiDark),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: formulas
                .map(
                  (formula) => _FormulaChip(
                    formula: formula,
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: formula));
                      ToastHelper.showSuccess(context, 'Formula copied');
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  List<String> _extractFormulaBlocks(String value) {
    final output = <String>[];
    // Regex to match both $$ block math and $ inline math (with or without spaces)
    final formulaRegex = RegExp(
      r'\$\$\s*([\s\S]+?)\s*\$\$|\$\s*([^\$\n]+?)\s*\$',
      multiLine: true,
    );

    for (final match in formulaRegex.allMatches(value)) {
      final formula = (match.group(1) ?? match.group(2))?.trim();
      if (formula != null && formula.isNotEmpty && !output.contains(formula)) {
        output.add(formula);
      }
    }

    return output;
  }

  String _stripFormulaBlocks(String value) {
    // Strip $$ delimiters while preserving content and inline context
    // This regex matches both $$ and $ delimiters with optional spaces
    final processedValue = value
        .replaceAll(RegExp(r'\$\$\s*([\s\S]+?)\s*\$\$', multiLine: true), '')
        .replaceAll(RegExp(r'\$\s*([^\$\n]+?)\s*\$', multiLine: true), '');
    return processedValue.trim();
  }
}

class FormulaElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final text = element.textContent;
    if (text.isEmpty) return null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.aiLightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.aiBorder),
      ),
      child: Math.tex(
        text,
        mathStyle: MathStyle.display,
        textStyle: const TextStyle(fontSize: 16),
        onErrorFallback: (_) => Text(text),
      ),
    );
  }
}

class _FormulaChip extends StatelessWidget {
  final String formula;
  final VoidCallback onCopy;

  const _FormulaChip({required this.formula, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.aiLightBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Math.tex(
              formula,
              mathStyle: MathStyle.display,
              textStyle: const TextStyle(fontSize: 13),
              onErrorFallback: (_) => Text(formula),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onCopy,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.copy_rounded,
                size: 15,
                color: AppColors.aiDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
