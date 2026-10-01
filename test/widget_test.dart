// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:decagrade/config/theme.dart';
import 'package:decagrade/screens/main/flashcards_screen.dart';
import 'package:decagrade/screens/main/pdf_viewer_screen.dart';
import 'package:decagrade/widgets/mascots/svg_mascot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app theme renders without a platform Firebase plugin', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Text('DecaGrade')),
      ),
    );

    expect(find.text('DecaGrade'), findsOneWidget);
  });

  testWidgets('flashcards screen renders a question and answer entry point', (
    WidgetTester tester,
  ) async {
    final colors = <String, Color>{
      'primary': AppColors.mathPrimary,
      'dark': AppColors.mathDark,
      'light': AppColors.mathLightBg,
      'border': AppColors.mathBorder,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: FlashcardsScreen(
          flashcards: [
            {
              'front': 'What is a real number?',
              'back': 'A real number is any number on the number line.',
            },
          ],
          chapterTitle: 'Real Numbers',
          colors: colors,
          mascotType: MascotType.calculo,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('What is a real number?'), findsOneWidget);
    expect(find.text('Tap to reveal answer'), findsOneWidget);
  });

  testWidgets(
    'pdf viewer shows a friendly unavailable state for missing urls',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PdfViewerScreen(
            url: '',
            title: 'Missing PDF',
            colors: {
              'primary': AppColors.primary,
              'dark': AppColors.primaryDark,
              'light': AppColors.backgroundSecondary,
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Content Unavailable'), findsOneWidget);
      expect(
        find.text('This study material is not available right now.'),
        findsOneWidget,
      );
      expect(find.text('RETRY'), findsOneWidget);
    },
  );
}
