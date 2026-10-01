import 'package:flutter_test/flutter_test.dart';
import 'package:decagrade/services/update_checker.dart';

void main() {
  group('UpdateChecker.isVersionNewer', () {
    test('detects a greater patch, minor, and major version', () {
      expect(UpdateChecker.isVersionNewer('1.0.1', '1.0.0'), isTrue);
      expect(UpdateChecker.isVersionNewer('1.1.0', '1.0.9'), isTrue);
      expect(UpdateChecker.isVersionNewer('2.0.0', '1.99.99'), isTrue);
    });

    test('treats omitted trailing zero components as equivalent', () {
      expect(UpdateChecker.isVersionNewer('1.0.0', '1.0'), isFalse);
      expect(UpdateChecker.isVersionNewer('1.0', '1.0.0'), isFalse);
    });

    test('accepts a v prefix and rejects malformed versions', () {
      expect(UpdateChecker.isVersionNewer('v1.2.0', '1.1.9'), isTrue);
      expect(UpdateChecker.isVersionNewer('latest', '1.0.0'), isFalse);
      expect(UpdateChecker.isVersionNewer('1.1.0', 'unknown'), isFalse);
    });
  });
}
