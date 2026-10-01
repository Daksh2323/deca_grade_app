import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class GamificationService {
  Future<Map<String, dynamic>> update({
    required String action,
    int? score,
    int? totalQuestions,
    String? badgeId,
    String? referralCode,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('AUTH_REQUIRED');
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) throw Exception('AUTH_REQUIRED');

    final payload = <String, dynamic>{'action': action};
    if (score != null) payload['score'] = score;
    if (totalQuestions != null) payload['total_questions'] = totalQuestions;
    if (badgeId != null) payload['badge_id'] = badgeId;
    if (referralCode != null) payload['referral_code'] = referralCode;

    final response = await http
        .post(
          Uri.parse('${ApiConfig.backendBaseUrl}/api/gamification/update'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(_error(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _error(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['detail'] is String) return body['detail'] as String;
    } catch (_) {}
    return 'Gamification service error (${response.statusCode})';
  }
}
