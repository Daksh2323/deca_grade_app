import 'package:flutter_test/flutter_test.dart';
import 'package:decagrade/services/firestore_service.dart';

void main() {
  group('study material normalization', () {
    test('normalizes subject aliases to the canonical Firestore value', () {
      expect(FirestoreService.normalizeStudySubject('Math'), 'Mathematics');
      expect(FirestoreService.normalizeStudySubject('math'), 'Mathematics');
      expect(FirestoreService.normalizeStudySubject('Eng'), 'English');
      expect(
        FirestoreService.normalizeStudySubject('English Language'),
        'English',
      );
      expect(
        FirestoreService.normalizeStudySubject('Social'),
        'Social Science',
      );
      expect(
        FirestoreService.normalizeStudySubject('social science'),
        'Social Science',
      );
      expect(
        FirestoreService.normalizeStudySubject('Information Technology'),
        'Information Technology',
      );
    });

    test('matches normalized values even when legacy aliases are used', () {
      final material = {
        'subject': 'Mathematics',
        'chapter': 'Real Numbers',
        'content_type': 'Notes',
        'status': 'published',
      };

      expect(
        FirestoreService.matchesPublishedMaterialFilter(
          material,
          subject: 'Math',
          chapter: 'Real Numbers',
          contentType: 'notes',
        ),
        isTrue,
      );
    });

    test('normalizes content types to the exact Firestore values', () {
      expect(FirestoreService.normalizeContentType('notes'), 'Notes');
      expect(FirestoreService.normalizeContentType('pyq'), 'PYQs');
      expect(
        FirestoreService.normalizeContentType('question_bank'),
        'Question Banks',
      );
      expect(
        FirestoreService.normalizeContentType('Sample Papers'),
        'Sample Papers',
      );
    });

    test('normalizes the UI label to the exact Firestore chapter name', () {
      expect(
        FirestoreService.normalizeChapterName('📝 Full Syllabus & Exam Prep'),
        'General / Full Syllabus',
      );
      expect(
        FirestoreService.normalizeChapterName('General / Full Syllabus'),
        'General / Full Syllabus',
      );
    });

    test(
      'keeps General / Full Syllabus constrained to the exact chapter while allowing PYQs and other types',
      () {
        final generalMaterial = {
          'subject': 'Mathematics',
          'chapter': 'General / Full Syllabus',
          'content_type': 'PYQs',
          'status': 'published',
        };

        final unrelatedChapterMaterial = {
          'subject': 'Mathematics',
          'chapter': 'Real Numbers',
          'content_type': 'PYQs',
          'status': 'published',
        };

        expect(
          FirestoreService.matchesPublishedMaterialFilter(
            generalMaterial,
            subject: 'Mathematics',
            chapter: 'General / Full Syllabus',
            contentType: 'PYQs',
          ),
          isTrue,
        );

        expect(
          FirestoreService.matchesPublishedMaterialFilter(
            unrelatedChapterMaterial,
            subject: 'Mathematics',
            chapter: 'General / Full Syllabus',
            contentType: 'PYQs',
          ),
          isFalse,
        );
      },
    );

    test(
      'filters out ghost placeholder chapters without real names or content',
      () {
        final validChapter = {
          'title': 'A Letter to God',
          'pdfs': [
            {'url': 'https://example.com/a-letter-to-god.pdf'},
          ],
          'flashcards': [
            {'front': 'Q1', 'back': 'A1'},
          ],
        };

        final ghostChapter = {'title': 'Chapter', 'pdfs': [], 'flashcards': []};

        final emptyTitleChapter = {'title': '', 'pdfs': [], 'flashcards': []};

        expect(FirestoreService.isRealChapter(validChapter), isTrue);
        expect(FirestoreService.isRealChapter(ghostChapter), isFalse);
        expect(FirestoreService.isRealChapter(emptyTitleChapter), isFalse);
      },
    );
  });
}
