import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGeneratorService {
  static Future<String> generateQuestionPaper({
    required String subjectName,
    required int totalMarks,
    required List<Map<String, dynamic>> mcqs,
    required List<Map<String, dynamic>> subjective,
  }) async {
    final pdf = pw.Document();
    final regular = pw.Font.helvetica();
    final bold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'DECAGRADE MOCK EXAMINATION',
              style: pw.TextStyle(font: bold, fontSize: 18),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'Class 10 CBSE - Subject: $subjectName',
              style: pw.TextStyle(font: bold, fontSize: 14),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Time Allowed: ${totalMarks == 20
                    ? '45 Mins'
                    : totalMarks == 40
                    ? '90 Mins'
                    : '3 Hours'}',
                style: pw.TextStyle(font: regular),
              ),
              pw.Text(
                'Maximum Marks: $totalMarks',
                style: pw.TextStyle(font: bold),
              ),
            ],
          ),
          pw.Divider(thickness: 2),
          pw.Text('General Instructions:', style: pw.TextStyle(font: bold)),
          pw.Text(
            '1. Section A consists of Multiple Choice Questions.',
            style: pw.TextStyle(font: regular),
          ),
          pw.Text(
            '2. Section B consists of Subjective/Descriptive Questions.',
            style: pw.TextStyle(font: regular),
          ),
          pw.SizedBox(height: 20),
          if (mcqs.isNotEmpty) ...[
            pw.Text(
              'SECTION A (Multiple Choice Questions)',
              style: pw.TextStyle(font: bold, fontSize: 14),
            ),
            pw.SizedBox(height: 10),
            ...mcqs.asMap().entries.map((entry) {
              final question = entry.value;
              final options = question['options'] is List
                  ? question['options'] as List
                  : const [];
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Q${entry.key + 1}. ${question['question'] ?? ''}',
                    style: pw.TextStyle(font: bold),
                  ),
                  ...options.asMap().entries.map(
                    (option) => pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 20, top: 3),
                      child: pw.Text(
                        '(${String.fromCharCode(65 + option.key)}) ${option.value}',
                        style: pw.TextStyle(font: regular),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 15),
                ],
              );
            }),
          ],
          if (subjective.isNotEmpty) ...[
            pw.Divider(),
            pw.Text(
              'SECTION B (Subjective Questions)',
              style: pw.TextStyle(font: bold, fontSize: 14),
            ),
            pw.SizedBox(height: 10),
            ...subjective.asMap().entries.map((entry) {
              final question = entry.value;
              final marks = question['marks'] is num
                  ? question['marks'] as num
                  : 3;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Q${mcqs.length + entry.key + 1}. ${question['question'] ?? ''}',
                          style: pw.TextStyle(font: bold),
                        ),
                      ),
                      pw.Text(
                        '[$marks Marks]',
                        style: pw.TextStyle(font: bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                ],
              );
            }),
          ],
        ],
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'MARKING SCHEME & ANSWER KEY',
              style: pw.TextStyle(font: bold, fontSize: 16),
            ),
          ),
          pw.Divider(thickness: 2),
          if (mcqs.isNotEmpty) ...[
            pw.Text('SECTION A - ANSWERS', style: pw.TextStyle(font: bold)),
            ...mcqs.asMap().entries.map((entry) {
              final question = entry.value;
              final answer = question['correctAnswer'] is num
                  ? (question['correctAnswer'] as num).toInt()
                  : 0;
              final explanation = question['explanation']?.toString() ?? '';
              return pw.Padding(
                padding: const pw.EdgeInsets.only(top: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Q${entry.key + 1}. Option (${String.fromCharCode(65 + answer)})',
                      style: pw.TextStyle(font: bold),
                    ),
                    if (explanation.isNotEmpty)
                      pw.Text(
                        'Explanation: $explanation',
                        style: pw.TextStyle(
                          font: regular,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
          if (subjective.isNotEmpty) ...[
            pw.SizedBox(height: 15),
            pw.Text('SECTION B - SOLUTIONS', style: pw.TextStyle(font: bold)),
            ...subjective.asMap().entries.map(
              (entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Answer ${mcqs.length + entry.key + 1}:',
                      style: pw.TextStyle(font: bold),
                    ),
                    pw.Text(
                      entry.value['solution']?.toString() ??
                          'No solution provided.',
                      style: pw.TextStyle(font: regular),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/DecaGrade_MockTest_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
