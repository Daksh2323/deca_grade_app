import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _writeAdmin(
    String endpoint, {
    String? documentId,
    List<String> path = const [],
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('An authenticated admin account is required.');
    }

    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.backendBaseUrl}/api/admin/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (documentId != null) 'document_id': documentId,
        if (path.isNotEmpty) 'path': path,
        'data': data,
        'merge': merge,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Admin API write failed (${response.statusCode}).');
    }
  }

  // ═══════════════════════════════════════════════════════
  // SEED ALL DATA
  // ═══════════════════════════════════════════════════════
  Future<String> seedAllData() async {
    try {
      await seedBadges();
      await seedSubjects();
      await seedChapters();
      await seedQuizzes();
      await seedMockTests();
      await seedDailyQuiz();
      await seedPYQs();
      return '✅ All data seeded successfully!';
    } catch (e) {
      return '❌ Error: $e';
    }
  }

  // ═══════════════════════════════════════════════════════
  // SEED QUIZ QUESTIONS FOR CHAPTERS
  // ═══════════════════════════════════════════════════════
  Future<void> seedQuizzes() async {
    print('🌱 Seeding quizzes...');

    final quizzes = {
      'ch1_real_numbers': [
        {
          'question': 'What is the HCF of 12 and 18?',
          'options': ['3', '4', '6', '9'],
          'correctAnswer': 2,
          'explanation':
              'HCF (Highest Common Factor) of 12 and 18 is 6.\n\n12 = 2² × 3\n18 = 2 × 3²\nHCF = 2 × 3 = 6',
        },
        {
          'question': 'Is √2 a rational or irrational number?',
          'options': ['Rational', 'Irrational', 'Both', 'Neither'],
          'correctAnswer': 1,
          'explanation':
              '√2 is IRRATIONAL because it cannot be expressed as p/q where p and q are integers and q ≠ 0.',
        },
        {
          'question': 'What is Euclid\'s Division Lemma?',
          'options': [
            'a = bq + r, where 0 ≤ r < b',
            'a + b = c',
            'a × b = c',
            'a - b = c',
          ],
          'correctAnswer': 0,
          'explanation':
              'Euclid\'s Division Lemma: For any two positive integers a and b, there exist unique integers q and r such that a = bq + r, where 0 ≤ r < b.',
        },
        {
          'question': 'HCF × LCM equals?',
          'options': [
            'Sum of two numbers',
            'Difference of two numbers',
            'Product of two numbers',
            'None of these',
          ],
          'correctAnswer': 2,
          'explanation':
              'For any two positive integers a and b:\nHCF(a,b) × LCM(a,b) = a × b',
        },
        {
          'question': 'Which of these is a rational number?',
          'options': ['√3', 'π', '22/7', '√5'],
          'correctAnswer': 2,
          'explanation':
              '22/7 is rational because it\'s in the form p/q where p and q are integers. Others are irrational.',
        },
      ],
      'ch2_polynomials': [
        {
          'question': 'The degree of polynomial x³ + 2x² - 5 is:',
          'options': ['1', '2', '3', '5'],
          'correctAnswer': 2,
          'explanation':
              'The degree of a polynomial is the highest power of x. Here, highest power is 3, so degree = 3.',
        },
        {
          'question': 'Sum of zeros of ax² + bx + c = 0 is:',
          'options': ['-b/a', 'b/a', '-c/a', 'c/a'],
          'correctAnswer': 0,
          'explanation':
              'For quadratic ax² + bx + c:\nSum of zeros = -b/a\nProduct of zeros = c/a',
        },
        {
          'question': 'A polynomial of degree 2 is called:',
          'options': ['Linear', 'Quadratic', 'Cubic', 'Constant'],
          'correctAnswer': 1,
          'explanation':
              'Polynomial degrees:\n• 1 = Linear\n• 2 = Quadratic\n• 3 = Cubic\n• 0 = Constant',
        },
      ],
      'ch4_quadratic': [
        {
          'question': 'Quadratic formula is:',
          'options': [
            'x = -b/a',
            'x = (-b ± √(b²-4ac))/2a',
            'x = b/2a',
            'x = -b ± √(b²+4ac)',
          ],
          'correctAnswer': 1,
          'explanation':
              'The quadratic formula:\nx = (-b ± √(b²-4ac))/2a\n\nWhere b² - 4ac is called the discriminant.',
        },
        {
          'question': 'If discriminant D = 0, the roots are:',
          'options': [
            'Real and distinct',
            'Real and equal',
            'Imaginary',
            'No roots',
          ],
          'correctAnswer': 1,
          'explanation':
              'When D = 0:\n• Roots are real and EQUAL\n• D > 0: Two distinct real roots\n• D < 0: No real roots',
        },
      ],
    };

    int totalCount = 0;
    for (var entry in quizzes.entries) {
      final chapterId = entry.key;
      final questions = entry.value;

      for (int i = 0; i < questions.length; i++) {
        await _writeAdmin(
          'content',
          path: [
            'cbse',
            'class10',
            'math',
            'chapters',
            chapterId,
            'quiz',
            'q${i + 1}',
          ],
          data: questions[i],
          merge: false,
        );
        totalCount++;
      }
      print('   ✓ Added ${questions.length} questions for $chapterId');
    }

    print('✅ Seeded $totalCount quiz questions');
  }

  // ═══════════════════════════════════════════════════════
  // SEED BADGES
  // ═══════════════════════════════════════════════════════
  Future<void> seedBadges() async {
    final badges = [
      {
        'id': 'streak_7',
        'name': 'Week Warrior',
        'description': 'Complete a 7-day study streak',
        'icon': '🔥',
        'xpReward': 100,
        'rarity': 'common',
      },
      {
        'id': 'streak_30',
        'name': 'Monthly Master',
        'description': 'Complete a 30-day study streak',
        'icon': '🏆',
        'xpReward': 500,
        'rarity': 'epic',
      },
      {
        'id': 'first_quiz',
        'name': 'Quiz Rookie',
        'description': 'Complete your first quiz',
        'icon': '🎯',
        'xpReward': 50,
        'rarity': 'common',
      },
      {
        'id': 'quiz_master',
        'name': 'Quiz Master',
        'description': 'Complete 50 quizzes',
        'icon': '👑',
        'xpReward': 300,
        'rarity': 'rare',
      },
      {
        'id': 'perfectionist',
        'name': 'Perfectionist',
        'description': 'Score 100% in any quiz',
        'icon': '💯',
        'xpReward': 200,
        'rarity': 'rare',
      },
      {
        'id': 'night_owl',
        'name': 'Night Owl',
        'description': 'Study after 10 PM',
        'icon': '🦉',
        'xpReward': 30,
        'rarity': 'common',
      },
      {
        'id': 'early_bird',
        'name': 'Early Bird',
        'description': 'Study before 7 AM',
        'icon': '🌅',
        'xpReward': 30,
        'rarity': 'common',
      },
      {
        'id': 'ai_explorer',
        'name': 'AI Explorer',
        'description': 'Ask AI Tutor 10 questions',
        'icon': '🤖',
        'xpReward': 75,
        'rarity': 'common',
      },
      {
        'id': 'subject_champion',
        'name': 'Subject Champion',
        'description': 'Complete all chapters in one subject',
        'icon': '⭐',
        'xpReward': 1000,
        'rarity': 'legendary',
      },
      {
        'id': 'referrer',
        'name': 'Influencer',
        'description': 'Refer 5 friends',
        'icon': '🎁',
        'xpReward': 250,
        'rarity': 'rare',
      },
    ];

    for (var badge in badges) {
      await _writeAdmin(
        'badges',
        documentId: badge['id'] as String,
        data: badge,
        merge: false,
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  // SEED SUBJECTS (For Class 10 CBSE)
  // ═══════════════════════════════════════════════════════
  Future<void> seedSubjects() async {
    final subjects = [
      {
        'id': 'math',
        'name': 'Mathematics',
        'icon': '🔢',
        'color': '#4F8EF7',
        'totalChapters': 15,
        'description': 'Numbers, algebra, geometry & more',
      },
      {
        'id': 'science',
        'name': 'Science',
        'icon': '🔬',
        'color': '#10B981',
        'totalChapters': 16,
        'description': 'Physics, chemistry & biology',
      },
      {
        'id': 'english',
        'name': 'English',
        'icon': '📚',
        'color': '#8B5CF6',
        'totalChapters': 12,
        'description': 'Literature & language',
      },
      {
        'id': 'social',
        'name': 'Social Science',
        'icon': '🌍',
        'color': '#F59E0B',
        'totalChapters': 20,
        'description': 'History, geography & civics',
      },
    ];

    for (var subject in subjects) {
      await _writeAdmin(
        'content',
        path: ['cbse', 'class10', subject['id'] as String],
        data: subject,
        merge: false,
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  // SEED CHAPTERS (Math Class 10 CBSE)
  // ═══════════════════════════════════════════════════════
  Future<void> seedChapters() async {
    final mathChapters = [
      {
        'id': 'ch1_real_numbers',
        'chapterNumber': 1,
        'title': 'Real Numbers',
        'description':
            'Euclid\'s division lemma, rational and irrational numbers',
        'notesShort':
            'Real numbers include rational and irrational numbers. Every composite number can be expressed as a product of primes uniquely.',
        'notesDetailed':
            'The Fundamental Theorem of Arithmetic states that every composite number can be expressed as a product of prime numbers, and this factorization is unique (except for the order of primes). Euclid\'s division lemma states that for any two positive integers a and b, there exist unique integers q and r such that a = bq + r, where 0 ≤ r < b.',
        'formulas': [
          'HCF × LCM = Product of two numbers',
          'a = bq + r where 0 ≤ r < b',
          '√(irrational) = irrational number',
        ],
        'flashcards': [
          {
            'front': 'What is Euclid\'s Division Lemma?',
            'back':
                'For positive integers a and b, there exist unique q and r such that a = bq + r, where 0 ≤ r < b',
          },
          {
            'front': 'Give an example of irrational number',
            'back': '√2, √3, π (pi), e (Euler\'s number)',
          },
          {'front': 'HCF × LCM = ?', 'back': 'Product of the two numbers'},
        ],
        'estimatedTime': 45,
        'isPublished': true,
      },
      {
        'id': 'ch2_polynomials',
        'chapterNumber': 2,
        'title': 'Polynomials',
        'description': 'Zeros, degrees, and division algorithm',
        'notesShort':
            'A polynomial in variable x is an expression of the form p(x) = anxn + an-1xn-1 + ... + a1x + a0',
        'notesDetailed':
            'The highest power of x in polynomial p(x) is called the degree of the polynomial. A polynomial of degree 1 is linear, degree 2 is quadratic, degree 3 is cubic.',
        'formulas': [
          'Sum of zeros = -b/a',
          'Product of zeros = c/a',
          'Division algorithm: Dividend = Divisor × Quotient + Remainder',
        ],
        'flashcards': [
          {
            'front': 'What is the degree of x³ + 2x² - 5?',
            'back': '3 (cubic polynomial)',
          },
          {
            'front': 'Sum of zeros formula?',
            'back': 'Sum of zeros = -b/a for ax² + bx + c',
          },
        ],
        'estimatedTime': 40,
        'isPublished': true,
      },
      {
        'id': 'ch3_linear_equations',
        'chapterNumber': 3,
        'title': 'Pair of Linear Equations',
        'description': 'Solving linear equations in two variables',
        'notesShort':
            'A pair of linear equations in two variables can be solved by substitution, elimination, or cross-multiplication methods.',
        'notesDetailed':
            'Two linear equations in two variables are consistent if they have at least one solution, inconsistent if they have no solution.',
        'formulas': [
          'For a₁x + b₁y + c₁ = 0 and a₂x + b₂y + c₂ = 0:',
          'Unique solution: a₁/a₂ ≠ b₁/b₂',
          'No solution: a₁/a₂ = b₁/b₂ ≠ c₁/c₂',
          'Infinite solutions: a₁/a₂ = b₁/b₂ = c₁/c₂',
        ],
        'flashcards': [
          {
            'front': 'Methods to solve linear equations?',
            'back':
                'Substitution, Elimination, Cross-multiplication, Graphical',
          },
        ],
        'estimatedTime': 50,
        'isPublished': true,
      },
      {
        'id': 'ch4_quadratic',
        'chapterNumber': 4,
        'title': 'Quadratic Equations',
        'description': 'Solving quadratic equations',
        'notesShort':
            'ax² + bx + c = 0 where a ≠ 0 is a quadratic equation. Solutions found using factoring, quadratic formula, or completing the square.',
        'notesDetailed':
            'The quadratic formula gives roots as x = (-b ± √(b²-4ac))/2a. The discriminant D = b²-4ac determines nature of roots.',
        'formulas': [
          'Quadratic formula: x = (-b ± √(b²-4ac))/2a',
          'Discriminant: D = b² - 4ac',
          'D > 0: Two distinct real roots',
          'D = 0: One repeated real root',
          'D < 0: No real roots',
        ],
        'flashcards': [
          {'front': 'Quadratic formula?', 'back': 'x = (-b ± √(b²-4ac))/2a'},
          {'front': 'When are roots equal?', 'back': 'When discriminant D = 0'},
        ],
        'estimatedTime': 55,
        'isPublished': true,
      },
      {
        'id': 'ch5_arithmetic',
        'chapterNumber': 5,
        'title': 'Arithmetic Progressions',
        'description': 'AP series, nth term, and sum of AP',
        'notesShort':
            'An AP is a sequence where the difference between consecutive terms is constant, called common difference (d).',
        'notesDetailed':
            'General AP: a, a+d, a+2d, a+3d, ... The nth term of AP is aₙ = a + (n-1)d.',
        'formulas': [
          'nth term: aₙ = a + (n-1)d',
          'Sum of n terms: Sₙ = n/2[2a + (n-1)d]',
          'Sum when last term known: Sₙ = n/2(a + l)',
        ],
        'flashcards': [
          {'front': 'nth term of AP?', 'back': 'aₙ = a + (n-1)d'},
        ],
        'estimatedTime': 45,
        'isPublished': true,
      },
    ];

    for (var chapter in mathChapters) {
      await _writeAdmin(
        'content',
        path: ['cbse', 'class10', 'math', 'chapters', chapter['id'] as String],
        data: chapter,
        merge: false,
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  // SEED MOCK TESTS
  // ═══════════════════════════════════════════════════════
  Future<void> seedMockTests() async {
    final tests = [
      {
        'id': 'mock_math_1',
        'title': 'Math Full Mock Test',
        'subject': 'Mathematics',
        'duration': 180,
        'totalQuestions': 40,
        'totalMarks': 80,
        'difficulty': 'medium',
        'description': 'Full syllabus mock test for Class 10 Math',
      },
      {
        'id': 'mock_science_1',
        'title': 'Science Full Mock Test',
        'subject': 'Science',
        'duration': 180,
        'totalQuestions': 40,
        'totalMarks': 80,
        'difficulty': 'medium',
        'description': 'Full syllabus mock test for Class 10 Science',
      },
    ];

    for (var test in tests) {
      await _writeAdmin(
        'mock-tests',
        documentId: test['id'] as String,
        data: test,
        merge: false,
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  // SEED DAILY QUIZ
  // ═══════════════════════════════════════════════════════════════
  Future<void> seedDailyQuiz() async {
    print('🌱 Seeding daily quizzes...');

    final today = DateTime.now();

    final questionSets = [
      [
        {
          'question': 'What is the HCF of 12 and 18?',
          'options': ['3', '4', '6', '9'],
          'correctAnswer': 2,
          'explanation':
              'HCF of 12 and 18 = 6.\n12 = 2² × 3\n18 = 2 × 3²\nHCF = 2 × 3 = 6',
        },
        {
          'question': 'Is √2 rational or irrational?',
          'options': ['Rational', 'Irrational', 'Both', 'Neither'],
          'correctAnswer': 1,
          'explanation': '√2 is IRRATIONAL as it cannot be expressed as p/q.',
        },
        {
          'question': 'HCF × LCM = ?',
          'options': ['Sum', 'Difference', 'Product of numbers', 'None'],
          'correctAnswer': 2,
          'explanation': 'HCF × LCM = Product of two numbers',
        },
        {
          'question': 'What is Euclid\'s Division Lemma?',
          'options': [
            'a = bq + r, 0 ≤ r < b',
            'a + b = c',
            'a × b = c',
            'a - b = c',
          ],
          'correctAnswer': 0,
          'explanation':
              'For any two positive integers a and b, unique q and r exist.',
        },
        {
          'question': 'Which is a rational number?',
          'options': ['√3', 'π', '22/7', '√5'],
          'correctAnswer': 2,
          'explanation': '22/7 is rational (p/q form). Others are irrational.',
        },
      ],
      [
        {
          'question': 'Degree of x³ + 2x² - 5?',
          'options': ['1', '2', '3', '5'],
          'correctAnswer': 2,
          'explanation': 'Highest power of x is 3, so degree = 3.',
        },
        {
          'question': 'Sum of zeros of ax² + bx + c?',
          'options': ['-b/a', 'b/a', '-c/a', 'c/a'],
          'correctAnswer': 0,
          'explanation': 'Sum of zeros = -b/a',
        },
        {
          'question': 'Polynomial of degree 2 is?',
          'options': ['Linear', 'Quadratic', 'Cubic', 'Constant'],
          'correctAnswer': 1,
          'explanation': 'Degree 2 = Quadratic',
        },
        {
          'question': 'Product of zeros of ax² + bx + c?',
          'options': ['-b/a', 'b/a', '-c/a', 'c/a'],
          'correctAnswer': 3,
          'explanation': 'Product of zeros = c/a',
        },
        {
          'question': 'Number of zeros of quadratic polynomial?',
          'options': ['1', '2', '3', '4'],
          'correctAnswer': 1,
          'explanation': 'Quadratic polynomial has maximum 2 zeros.',
        },
      ],
    ];

    int count = 0;
    for (int i = 0; i < 8; i++) {
      final date = today.add(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final setIndex = i % questionSets.length;
      final topics = ['Real Numbers', 'Polynomials'];

      await _writeAdmin(
        'daily-quiz',
        documentId: dateStr,
        data: {
          'date': dateStr,
          'subject': 'Mathematics',
          'topic': topics[setIndex],
          'xpReward': 50,
          'questions': questionSets[setIndex],
        },
        merge: false,
      );
      count++;
    }

    print('✅ Seeded $count daily quizzes');
  }

  // ═══════════════════════════════════════════════════════
  // SEED PREVIOUS YEAR QUESTIONS
  // ═══════════════════════════════════════════════════════
  Future<void> seedPYQs() async {
    final pyqs = [
      {
        'id': 'pyq_math_2023_1',
        'subject': 'Mathematics',
        'year': 2023,
        'question': 'Find the HCF of 96 and 404 by prime factorisation method.',
        'marks': 3,
        'chapter': 'Real Numbers',
        'solution':
            'Prime factors of 96 = 2⁵ × 3\nPrime factors of 404 = 2² × 101\nHCF = 2² = 4',
      },
      {
        'id': 'pyq_math_2023_2',
        'subject': 'Mathematics',
        'year': 2023,
        'question':
            'If one zero of the polynomial x² - 4x + k is 3, find the value of k.',
        'marks': 2,
        'chapter': 'Polynomials',
        'solution':
            'Since 3 is a zero: 3² - 4(3) + k = 0\n9 - 12 + k = 0\nk = 3',
      },
    ];

    for (var pyq in pyqs) {
      await _db.collection('pyqs').doc(pyq['id'] as String).set(pyq);
    }
  }
}
