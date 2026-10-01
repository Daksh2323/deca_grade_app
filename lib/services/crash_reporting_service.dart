import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService instance = CrashReportingService._();

  Future<void> recordFatal(Object error, StackTrace stack) async {
    try {
      await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {}
  }

  Future<void> recordNonFatal(Object error, StackTrace stack) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: false,
      );
    } catch (_) {}
  }

  Future<void> breadcrumb(String message) async {
    try {
      await FirebaseCrashlytics.instance.log(_sanitize(message));
    } catch (_) {}
  }

  String _sanitize(String message) {
    final value = message.replaceAll(RegExp(r'[\r\n]'), ' ').trim();
    return value.length <= 120 ? value : value.substring(0, 120);
  }
}
