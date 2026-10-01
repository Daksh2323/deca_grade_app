import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../widgets/duolingo_button.dart';
import '../../widgets/rich_markdown_view.dart';

class QpgResultScreen extends StatefulWidget {
  final String subject;
  final List<String> chapters;
  final int totalMarks;
  final Map<String, dynamic> paperData;

  const QpgResultScreen({
    super.key,
    required this.subject,
    required this.chapters,
    required this.totalMarks,
    required this.paperData,
  });

  @override
  State<QpgResultScreen> createState() => _QpgResultScreenState();
}

class _QpgResultScreenState extends State<QpgResultScreen> {
  final FirestoreService _firestore = FirestoreService();
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _saveToHistory();
  }

  Future<void> _saveToHistory() => _firestore.savePaperToHistory({
    'subject': widget.subject,
    'chapters': widget.chapters,
    'totalMarks': widget.totalMarks,
    'paperData': widget.paperData,
  });

  List<String> _strings(dynamic value) =>
      value is List ? value.map((v) => v.toString()).toList() : <String>[];
  List<Map<String, dynamic>> _questions(dynamic section) =>
      section is Map && section['questions'] is List
      ? (section['questions'] as List)
            .whereType<Map>()
            .map((q) => Map<String, dynamic>.from(q))
            .toList()
      : <Map<String, dynamic>>[];
  List<dynamic> get _sections => widget.paperData['sections'] is List
      ? widget.paperData['sections'] as List
      : const [];
  String _value(String key, String fallback) =>
      widget.paperData[key]?.toString() ?? fallback;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9),
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'CBSE Official Exam Paper',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Print',
          icon: const Icon(Icons.print_rounded, color: AppColors.primary),
          onPressed: _exportPdf,
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                // Allow text to take up full mobile width
                child: _buildPaperDocument(
                  _strings(widget.paperData['general_instructions']),
                  _sections,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: DuolingoButton(
              label: _exporting ? 'EXPORTING' : 'EXPORT / PRINT PDF',
              icon: Icons.print_rounded,
              color: AppColors.primary,
              darkColor: AppColors.primaryDark,
              height: 50,
              width: double.infinity,
              onPressed: _exportPdf,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildPaperDocument(
    List<String> rawInstructions,
    List<dynamic> rawSections,
  ) {
    final instructions = rawInstructions.isNotEmpty
        ? rawInstructions
        : <String>[
            'This question paper contains questions divided into sections.',
            'All questions are compulsory.',
            'Use of calculators is strictly prohibited.',
          ];
    final sections = rawSections.isNotEmpty
        ? rawSections
        : widget.paperData['questions'] is List
        ? <dynamic>[
            {
              'section_title': 'SECTION A - EXAMINATION QUESTIONS',
              'section_subtitle': 'Answer all questions below',
              'questions': widget.paperData['questions'],
            },
          ]
        : <dynamic>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                _value('institution_name', 'KENDRIYA VIDYALAYA SANGATHAN'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _value('subject', widget.subject.toUpperCase()),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _value('class_session', 'CLASS: X (2024-25)'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _value('exam_name', 'MID-TERM EXAMINATION'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TIME: ${_value('time_allowed', '3 HOURS')}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            Text(
              'M.M. - ${_value('max_marks', widget.totalMarks.toString())}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
        ),
        const Divider(color: Color(0xFF0F172A), thickness: 1.5),
        const SizedBox(height: 12),
        const Text(
          'General Instructions:',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            decoration: TextDecoration.underline,
          ),
        ),
        const SizedBox(height: 8),
        ...instructions.map(
          (instruction) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    instruction,
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Table(
          border: TableBorder.all(color: const Color(0xFF64748B)),
          columnWidths: const {
            0: FixedColumnWidth(40), // Narrower Q.NO.
            1: FlexColumnWidth(),
            2: FixedColumnWidth(45), // Narrower MARKS
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
              children: [
                _buildHeaderCell('Q.NO.'),
                _buildHeaderCell('QUESTIONS'),
                _buildHeaderCell('MARKS'),
              ],
            ),
            if (sections.isEmpty)
              const TableRow(
                children: [
                  SizedBox(),
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No questions generated. Please tap Back and try again.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(),
                ],
              )
            else
              for (final section in sections) ...[
                _sectionRow(section),
                ..._questions(section).map(_questionRow),
              ],
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
    child: Text(
      title,
      textAlign: TextAlign.center,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Color(0xFF0F172A),
        letterSpacing: 0.5,
      ),
    ),
  );

  TableRow _sectionRow(dynamic section) => TableRow(
    children: [
      const SizedBox(),
      Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              section is Map ? section['section_title']?.toString() ?? '' : '',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            Text(
              section is Map
                  ? section['section_subtitle']?.toString() ?? ''
                  : '',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(),
    ],
  );

  TableRow _questionRow(Map<String, dynamic> question) => TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          '${question['q_no'] ?? ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichMarkdownView(
              content: question['question']?.toString() ?? '',
              selectable: true,
              padding: const EdgeInsets.all(0),
            ),
            ..._strings(question['options']).map(
              (option) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 6),
                child: RichMarkdownView(
                  content: option,
                  selectable: true,
                  padding: const EdgeInsets.all(0),
                ),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          '${question['marks'] ?? ''}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    ],
  );

  String _pdfText(dynamic value) =>
      value?.toString().replaceAll(RegExp(r'\$(.*?)\$'), r'$1') ?? '';

  Future<void> _exportPdf() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    HapticFeedback.mediumImpact();
    try {
      final regular = const pw.TextStyle(fontSize: 9);
      final bold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (_) => [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    _value('institution_name', 'KENDRIYA VIDYALAYA SANGATHAN'),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _value('subject', widget.subject.toUpperCase()),
                    style: bold,
                  ),
                  pw.Text(
                    _value('class_session', 'CLASS: X (2024-25'),
                    style: regular,
                  ),
                  pw.Text(
                    _value('exam_name', 'MID-TERM EXAMINATION'),
                    style: bold,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TIME: ${_value('time_allowed', '3 HOURS')}',
                  style: bold,
                ),
                pw.Text(
                  'M.M. - ${_value('max_marks', widget.totalMarks.toString())}',
                  style: bold,
                ),
              ],
            ),
            pw.Divider(),
            pw.Text('General Instructions:', style: bold),
            ..._strings(
              widget.paperData['general_instructions'],
            ).map((i) => pw.Bullet(text: i, style: regular)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey700, width: .8),
              columnWidths: const {
                0: pw.FixedColumnWidth(40),
                1: pw.FlexColumnWidth(),
                2: pw.FixedColumnWidth(45),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: ['Q.NO.', 'QUESTIONS', 'MARKS']
                      .map(
                        (v) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            v,
                            style: bold,
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      )
                      .toList(),
                ),
                for (final section in _sections) ...[
                  _pdfSectionRow(section, bold, regular),
                  ..._questions(
                    section,
                  ).map((q) => _pdfQuestionRow(q, regular, bold)),
                ],
              ],
            ),
          ],
        ),
      );
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'KVS_ExamPaper_${widget.subject}.pdf',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF export failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  pw.TableRow _pdfSectionRow(
    dynamic section,
    pw.TextStyle bold,
    pw.TextStyle regular,
  ) => pw.TableRow(
    children: [
      pw.SizedBox(),
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Column(
          children: [
            pw.Text(
              section is Map ? section['section_title']?.toString() ?? '' : '',
              style: bold,
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              section is Map
                  ? section['section_subtitle']?.toString() ?? ''
                  : '',
              style: regular,
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
      pw.SizedBox(),
    ],
  );

  pw.TableRow _pdfQuestionRow(
    Map<String, dynamic> q,
    pw.TextStyle regular,
    pw.TextStyle bold,
  ) => pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          '${q['q_no'] ?? ''}',
          style: bold,
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_pdfText(q['question']), style: regular),
            ..._strings(
              q['options'],
            ).map((o) => pw.Text(_pdfText(o), style: regular)),
          ],
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          '${q['marks'] ?? ''}',
          style: bold,
          textAlign: pw.TextAlign.center,
        ),
      ),
    ],
  );
}
