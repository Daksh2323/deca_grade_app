import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class GeminiService {
  final List<Map<String, String>> _history = [];
  static const int _maxHistoryContentLength = 8000;

  String _boundedHistoryContent(String content) {
    final runes = content.runes;
    if (runes.length <= _maxHistoryContentLength) return content;
    return String.fromCharCodes(
      runes.skip(runes.length - _maxHistoryContentLength),
    );
  }

  Future<String> _request(
    String message, {
    String? subject,
    String? mode,
    List<int>? imageBytes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('AUTH_REQUIRED');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('AUTH_REQUIRED');

    final body = <String, dynamic>{
      'message': message,
      'subject': subject,
      'mode': mode,
      'history': _history
          .map(
            (entry) => {
              'role': entry['role']!,
              'content': _boundedHistoryContent(entry['content']!),
            },
          )
          .toList(),
    };
    if (imageBytes != null) {
      body['image_base64'] = base64Encode(imageBytes);
      body['image_mime_type'] = 'image/jpeg';
    }

    final response = await http
        .post(
          Uri.parse('${ApiConfig.backendBaseUrl}/api/ai/chat'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      throw Exception(_backendError(response));
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text = decoded['text'];
    if (text is! String || text.isEmpty) throw Exception('EMPTY_RESPONSE');
    _history
      ..add({'role': 'user', 'content': message})
      ..add({'role': 'model', 'content': text});
    if (_history.length > 20) {
      _history.removeRange(0, _history.length - 20);
    }
    return text;
  }

  String _backendError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (_) {}
    return 'AI service error (${response.statusCode})';
  }

  Future<String> sendMessage(String userMessage, {String? subject}) {
    return _request(userMessage, subject: subject);
  }

  Future<String> voiceChat(String message, {String? mode, String? language}) {
    final languageInstruction = language == null ? '' : ' Reply in $language.';
    return _request('$message$languageInstruction', mode: mode);
  }

  Future<String> solveFromImage({
    required List<int> imageBytes,
    String? subject,
    String? customPrompt,
  }) {
    return _request(
      customPrompt ?? 'Analyze this study image and solve it step by step.',
      subject: subject,
      imageBytes: imageBytes,
    );
  }

  Future<String> solveWithImage({
    required List<int> imageBytes,
    String? subject,
    String? customPrompt,
  }) => solveFromImage(
    imageBytes: imageBytes,
    subject: subject,
    customPrompt: customPrompt,
  );

  Future<String> generateQuestionPaper({
    required String subject,
    required List<String> chapters,
    required int totalMarks,
    required int mcqCount,
    required int twoMarkCount,
    required int threeMarkCount,
    required int fiveMarkCount,
  }) {
    return _request(
      'Generate a formal CBSE Class 10 question paper in Markdown for $subject. '
      'Chapters: ${chapters.join(', ')}. Marks: $totalMarks. '
      'Counts: $mcqCount MCQ, $twoMarkCount two-mark, '
      '$threeMarkCount three-mark, $fiveMarkCount five-mark questions.',
      subject: subject,
    );
  }

  Future<Map<String, dynamic>> generateQuestionPaperJson({
    required String subject,
    required List<String> chapters,
    required int totalMarks,
    required int mcqCount,
    required int twoMarkCount,
    required int threeMarkCount,
    required int fiveMarkCount,
  }) async {
    final text = await generateQuestionPaper(
      subject: subject,
      chapters: chapters,
      totalMarks: totalMarks,
      mcqCount: mcqCount,
      twoMarkCount: twoMarkCount,
      threeMarkCount: threeMarkCount,
      fiveMarkCount: fiveMarkCount,
    );
    final cleanJson = text
        .replaceFirst(RegExp(r'^\s*```json\s*'), '')
        .replaceFirst(RegExp(r'\s*```\s*$'), '')
        .trim();
    final decoded = jsonDecode(cleanJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The AI returned an invalid paper format.');
    }
    return decoded;
  }

  void resetChat() => _history.clear();
}
