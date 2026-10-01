import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class MathText extends StatelessWidget {
  final String content;
  final TextStyle? style;
  final TextStyle? mathStyle;
  final TextAlign textAlign;

  const MathText(
    this.content, {
    super.key,
    this.mathStyle,
    this.textAlign = TextAlign.start,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final segments = MathParser.parse(content);

    if (segments.length == 1 && segments.first.type == MathSegmentType.text) {
      return _RichPlainText(segments.first.text, baseStyle, textAlign);
    }

    return Wrap(
      alignment: textAlign == TextAlign.center
          ? WrapAlignment.center
          : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final segment in segments)
          if (segment.type == MathSegmentType.text)
            _RichPlainText(segment.text, baseStyle, textAlign)
          else
            _SafeMath(
              segment.text,
              segment.type == MathSegmentType.blockMath,
              mathStyle ?? baseStyle,
            ),
      ],
    );
  }
}

enum MathSegmentType { text, inlineMath, blockMath }

class MathSegment {
  final MathSegmentType type;
  final String text;

  MathSegment(this.type, this.text);
}

class MathParser {
  static final _blockPattern = RegExp(r'\$\$(.+?)\$\$', dotAll: true);
  static final _inlinePattern = RegExp(r'\$(?!\$)(.+?)(?<!\$)\$');
  static final _looksLikeMath = RegExp(r'[\^_{}\\]|[=+\-*/<>]|\\[a-zA-Z]+');

  static List<MathSegment> parse(String input) {
    final blockMatches = _blockPattern.allMatches(input).toList();
    if (blockMatches.isEmpty) return _parseInline(input);

    final segments = <MathSegment>[];
    var cursor = 0;
    for (final match in blockMatches) {
      if (match.start > cursor) {
        segments.addAll(_parseInline(input.substring(cursor, match.start)));
      }
      segments.add(
        MathSegment(MathSegmentType.blockMath, match.group(1)!.trim()),
      );
      cursor = match.end;
    }
    if (cursor < input.length) {
      segments.addAll(_parseInline(input.substring(cursor)));
    }
    return segments.isEmpty
        ? [MathSegment(MathSegmentType.text, input)]
        : segments;
  }

  static List<MathSegment> _parseInline(String input) {
    final segments = <MathSegment>[];
    var cursor = 0;
    for (final match in _inlinePattern.allMatches(input)) {
      final candidate = match.group(1)!.trim();
      if (match.start > cursor) {
        segments.add(
          MathSegment(
            MathSegmentType.text,
            input.substring(cursor, match.start),
          ),
        );
      }
      if (candidate.isNotEmpty && _looksLikeMath.hasMatch(candidate)) {
        segments.add(MathSegment(MathSegmentType.inlineMath, candidate));
      } else {
        segments.add(MathSegment(MathSegmentType.text, match.group(0)!));
      }
      cursor = match.end;
    }
    if (cursor < input.length) {
      segments.add(MathSegment(MathSegmentType.text, input.substring(cursor)));
    }
    return segments.isEmpty
        ? [MathSegment(MathSegmentType.text, input)]
        : segments;
  }
}

class _SafeMath extends StatelessWidget {
  final String expression;
  final bool isBlock;
  final TextStyle style;

  const _SafeMath(this.expression, this.isBlock, this.style);

  @override
  Widget build(BuildContext context) {
    final widget = Math.tex(
      expression,
      mathStyle: isBlock ? MathStyle.display : MathStyle.text,
      textStyle: style,
      onErrorFallback: (_) => Text(
        expression,
        style: style.copyWith(
          fontFamily: 'monospace',
          color: style.color?.withValues(alpha: 0.6),
        ),
      ),
    );
    if (isBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(child: widget),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: widget,
    );
  }
}

class _RichPlainText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final TextAlign align;

  const _RichPlainText(this.text, this.baseStyle, this.align);

  static final _boldPattern = RegExp(r'\*\*(.+?)\*\*');
  static final _italicPattern = RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)');

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    _emit(text, baseStyle, spans);
    return RichText(
      textAlign: align,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  void _emit(String input, TextStyle textStyle, List<InlineSpan> spans) {
    var cursor = 0;
    for (final match in _boldPattern.allMatches(input)) {
      if (match.start > cursor) {
        _emitItalic(input.substring(cursor, match.start), textStyle, spans);
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: textStyle.copyWith(fontWeight: FontWeight.bold),
        ),
      );
      cursor = match.end;
    }
    if (cursor < input.length) {
      _emitItalic(input.substring(cursor), textStyle, spans);
    }
  }

  void _emitItalic(String input, TextStyle textStyle, List<InlineSpan> spans) {
    var cursor = 0;
    for (final match in _italicPattern.allMatches(input)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: input.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: textStyle.copyWith(fontStyle: FontStyle.italic),
        ),
      );
      cursor = match.end;
    }
    if (cursor < input.length) {
      spans.add(TextSpan(text: input.substring(cursor)));
    }
  }
}
