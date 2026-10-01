import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logAppOpen() => _safe(() => _analytics.logAppOpen());

  Future<void> logViewChapter({
    required String subject,
    required String chapter,
  }) => _safe(
    () => _analytics.logEvent(
      name: 'view_chapter',
      parameters: {'subject': _value(subject), 'chapter_id': _value(chapter)},
    ),
  );

  Future<void> logOpenPdf({
    required String contentType,
    required String title,
  }) => _safe(
    () => _analytics.logEvent(
      name: 'open_pdf',
      parameters: {
        'content_type': _value(contentType),
        'document_title': _value(title),
      },
    ),
  );

  Future<void> logQuizStarted({
    required String subject,
    required String chapter,
  }) => _safe(
    () => _analytics.logEvent(
      name: 'quiz_started',
      parameters: {'subject': _value(subject), 'chapter_id': _value(chapter)},
    ),
  );

  Future<void> logQuizCompleted({
    required int score,
    required int totalQuestions,
  }) => _safe(
    () => _analytics.logEvent(
      name: 'quiz_completed',
      parameters: {'score': score, 'total_questions': totalQuestions},
    ),
  );

  Future<void> logAiChatUsed({required bool isPremiumUser}) => _safe(
    () => _analytics.logEvent(
      name: 'ai_chat_used',
      parameters: {'is_premium_user': isPremiumUser ? 1 : 0},
    ),
  );

  Future<void> logPremiumUpgradeViewed() =>
      _safe(() => _analytics.logEvent(name: 'premium_upgrade_viewed'));

  Future<void> logDailyLogin() =>
      _safe(() => _analytics.logEvent(name: 'daily_login'));

  String _value(String value) {
    final normalized = value.trim();
    return normalized.length <= 80 ? normalized : normalized.substring(0, 80);
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Analytics must never affect the user flow.
    }
  }
}
