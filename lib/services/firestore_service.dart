import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'gamification_service.dart';
import 'analytics_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  static String normalizeStudySubject(String? value) {
    if (value == null) return '';

    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final normalized = trimmed.toLowerCase();
    final aliasMap = {
      'eng': 'English',
      'math': 'Mathematics',
      'maths': 'Mathematics',
      'mathematics': 'Mathematics',
      'science': 'Science',
      'english': 'English',
      'english language': 'English',
      'english language and literature': 'English',
      'english literature': 'English',
      'english lang': 'English',
      'hindi': 'Hindi',
      'social': 'Social Science',
      'social science': 'Social Science',
      'sst': 'Social Science',
      'information technology': 'Information Technology',
      'it': 'Information Technology',
    };

    if (aliasMap.containsKey(normalized)) {
      return aliasMap[normalized]!;
    }

    if (normalized.contains('english')) return 'English';
    if (normalized.contains('math')) return 'Mathematics';
    if (normalized.contains('science')) return 'Science';
    if (normalized.contains('social') || normalized.contains('sst')) {
      return 'Social Science';
    }
    if (normalized.contains('it') ||
        normalized.contains('information technology')) {
      return 'Information Technology';
    }

    return trimmed;
  }

  static String normalizeContentType(String? value) {
    if (value == null) return '';

    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final normalized = trimmed.toLowerCase();
    final aliasMap = {
      'notes': 'Notes',
      'note': 'Notes',
      'pyq': 'PYQs',
      'pyqs': 'PYQs',
      'question bank': 'Question Banks',
      'question banks': 'Question Banks',
      'question_bank': 'Question Banks',
      'question_banks': 'Question Banks',
      'sample paper': 'Sample Papers',
      'sample papers': 'Sample Papers',
      'sample_paper': 'Sample Papers',
      'sample_papers': 'Sample Papers',
      'important_qs': 'Important Qs',
      'important qs': 'Important Qs',
      'important questions': 'Important Qs',
      'importantqs': 'Important Qs',
    };

    return aliasMap[normalized] ?? trimmed;
  }

  static String normalizeChapterName(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return '';

    final lowered = trimmed.toLowerCase();
    if (lowered.contains('full syllabus') || lowered.contains('exam prep')) {
      return 'General / Full Syllabus';
    }

    return trimmed;
  }

  static bool isGeneralSyllabusChapter(String? value) {
    return normalizeChapterName(value) == 'General / Full Syllabus';
  }

  static bool isRealChapter(Map<String, dynamic> chapter) {
    final title = (chapter['title'] ?? chapter['chapterName'] ?? '')
        .toString()
        .trim();
    final displayName = title.replaceAll(RegExp(r'\s+'), ' ');

    if (displayName.isEmpty ||
        displayName == 'Chapter' ||
        displayName == 'Unnamed Chapter') {
      return false;
    }

    final pdfs = chapter['pdfs'];
    final flashcards = chapter['flashcards'];
    final questions = chapter['questions'];
    final videos = chapter['videos'];

    final hasContent =
        (pdfs is List && pdfs.isNotEmpty) ||
        (flashcards is List && flashcards.isNotEmpty) ||
        (questions is List && questions.isNotEmpty) ||
        (videos is List && videos.isNotEmpty);

    return hasContent || displayName != 'Chapter';
  }

  static bool matchesPublishedMaterialFilter(
    Map<String, dynamic> item, {
    String? subject,
    String? chapter,
    String? contentType,
  }) {
    final itemStatus = (item['status'] ?? '').toString().trim().toLowerCase();
    if (itemStatus != 'published') return false;

    final itemSubject = normalizeStudySubject(item['subject']?.toString());
    final normalizedSubject = normalizeStudySubject(subject);
    if (normalizedSubject.isNotEmpty && itemSubject != normalizedSubject) {
      return false;
    }

    final itemChapter = (item['chapter'] ?? '').toString().trim();
    final normalizedChapter = (chapter ?? '').trim();
    final isGeneralSyllabus = isGeneralSyllabusChapter(normalizedChapter);
    if (normalizedChapter.isNotEmpty) {
      if (isGeneralSyllabus) {
        if (itemChapter != normalizedChapter) return false;
      } else {
        final itemChapterLower = itemChapter.toLowerCase();
        final chapterLower = normalizedChapter.toLowerCase();
        final chapterMatches =
            itemChapterLower == chapterLower ||
            itemChapterLower.contains(chapterLower) ||
            chapterLower.contains(itemChapterLower);
        if (!chapterMatches) return false;
      }
    }

    final itemContentType = normalizeContentType(
      (item['content_type'] ?? item['type'] ?? '').toString(),
    );
    final normalizedContentType = normalizeContentType(contentType);
    if (normalizedContentType.isNotEmpty &&
        itemContentType.isNotEmpty &&
        itemContentType != normalizedContentType) {
      return false;
    }

    return true;
  }

  Stream<List<Map<String, dynamic>>> streamPublishedStudyMaterials({
    String? subject,
    String? chapter,
    String? contentType,
  }) {
    final normalizedSubject = normalizeStudySubject(subject);
    final normalizedChapter = normalizeChapterName(chapter);
    final normalizedContentType = normalizeContentType(contentType);

    Query<Map<String, dynamic>> query = _db
        .collection('study_materials')
        .where('status', isEqualTo: 'published');

    if (normalizedSubject.isNotEmpty) {
      query = query.where('subject', isEqualTo: normalizedSubject);
    }

    if (normalizedChapter.isNotEmpty) {
      query = query.where('chapter', isEqualTo: normalizedChapter);
    }

    if (normalizedContentType.isNotEmpty) {
      query = query.where('content_type', isEqualTo: normalizedContentType);
    }

    query = query.limit(20);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> getPublishedStudyMaterials({
    String? subject,
    String? chapter,
    String? contentType,
  }) async {
    final normalizedSubject = normalizeStudySubject(subject);
    final normalizedChapter = normalizeChapterName(chapter);
    final normalizedContentType = normalizeContentType(contentType);

    try {
      Query<Map<String, dynamic>> query = _db
          .collection('study_materials')
          .where('status', isEqualTo: 'published');

      if (normalizedSubject.isNotEmpty) {
        query = query.where('subject', isEqualTo: normalizedSubject);
      }

      if (normalizedChapter.isNotEmpty) {
        query = query.where('chapter', isEqualTo: normalizedChapter);
      }

      if (normalizedContentType.isNotEmpty) {
        query = query.where('content_type', isEqualTo: normalizedContentType);
      }

      query = query.limit(20);

      final snapshot = await query.get();
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return docs;
    } catch (e) {
      print('❌ [DEBUG] FIRESTORE QUERY FAILED: $e');
      if (e.toString().toLowerCase().contains('index') ||
          e.toString().toLowerCase().contains('composite')) {}

      try {
        Query<Map<String, dynamic>> fallbackQuery = _db
            .collection('study_materials')
            .where('status', isEqualTo: 'published');

        if (normalizedSubject.isNotEmpty) {
          fallbackQuery = fallbackQuery.where(
            'subject',
            isEqualTo: normalizedSubject,
          );
        }

        fallbackQuery = fallbackQuery.limit(20);

        final fallbackSnapshot = await fallbackQuery.get();
        final fallbackDocs = fallbackSnapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            })
            .where(
              (item) => matchesPublishedMaterialFilter(
                item,
                subject: normalizedSubject,
                chapter: normalizedChapter,
                contentType: normalizedContentType,
              ),
            )
            .toList();

        return fallbackDocs;
      } catch (fallbackError) {
        print('❌ [DEBUG] Fallback Firestore query also failed: $fallbackError');
        return [];
      }
    }
  }

  // ═══ Mark Task Complete ═══
  Future<UserModel?> getCurrentUser() async {
    final authUser = _auth.currentUser;
    if (authUser == null) return null;

    final doc = await _db.collection('users').doc(authUser.uid).get();

    final data = doc.data();
    final displayName = authUser.displayName?.trim();
    if (data == null) {
      if (displayName == null || displayName.isEmpty) return null;
      return UserModel(
        uid: authUser.uid,
        name: displayName,
        email: authUser.email ?? '',
        userClass: 'Class 10',
        board: 'CBSE',
      );
    }

    if ((data['name']?.toString().trim().isEmpty ?? true) &&
        displayName != null &&
        displayName.isNotEmpty) {
      data['name'] = displayName;
    }
    return UserModel.fromMap(data);
  }

  Stream<UserModel?> streamUserData() {
    if (currentUserId == null) return Stream.value(null);

    return _db.collection('users').doc(currentUserId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    await _db.collection('users').doc(currentUserId).update(data);
  }

  // ═══ Update Streak (call daily on app open) ═══
  Future<Map<String, dynamic>> updateStreak() async {
    if (currentUserId == null) return {'success': false};

    try {
      final result = await GamificationService().update(action: 'daily_login');
      if (result['sameDay'] != true) {
        unawaited(AnalyticsService.instance.logDailyLogin());
      }
      return {
        ...result,
        'success': true,
        'increased': result['sameDay'] != true,
      };
    } catch (e) {
      print('❌ Error updating streak: $e');
      return {'success': false};
    }
  }

  // ═══ Earn a badge ═══
  Future<bool> earnBadge(String badgeId) async {
    if (currentUserId == null) return false;

    try {
      final result = await GamificationService().update(
        action: 'award_badge',
        badgeId: badgeId,
      );
      return (result['xpEarned'] as num?)?.toInt() != 0;
    } catch (e) {
      print('❌ Error earning badge: $e');
      return false;
    }
  }

  // ═══ Get all badges (both earned and locked) ═══
  Future<List<Map<String, dynamic>>> getAllBadges() async {
    if (currentUserId == null) return [];

    try {
      final userDoc = await _db.collection('users').doc(currentUserId).get();
      final userBadges = List<String>.from(userDoc.data()?['badges'] ?? []);

      final snapshot = await _db.collection('badges').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['earned'] = userBadges.contains(doc.id);
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error loading badges: $e');
      return [];
    }
  }

  // ═══ Use Streak Freeze ═══
  Future<bool> useStreakFreeze() async {
    if (currentUserId == null) return false;

    try {
      await GamificationService().update(action: 'use_streak_freeze');
      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══ Generate/Get User's Referral Code ═══
  Future<String> getUserReferralCode() async {
    if (currentUserId == null) return '';

    try {
      final userDoc = await _db.collection('users').doc(currentUserId).get();

      String? code = userDoc.data()?['referralCode'];

      if (code == null || code.isEmpty) {
        code = _generateReferralCode();
        await _db.collection('users').doc(currentUserId).update({
          'referralCode': code,
        });

        await _db.collection('referrals').doc(currentUserId).set({
          'userId': currentUserId,
          'code': code,
          'referredUsers': [],
          'totalReferrals': 0,
          'totalXpEarned': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return code;
    } catch (e) {
      print('❌ Error getting referral code: $e');
      return '';
    }
  }

  String _generateReferralCode() {
    final userId = currentUserId ?? '';
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String code = 'SV';

    final random = userId.hashCode.abs();
    for (int i = 0; i < 6; i++) {
      code += chars[(random + i * 7) % chars.length];
    }

    return code;
  }

  // ═══ Get User's Referral Stats ═══
  Future<Map<String, dynamic>> getReferralStats() async {
    if (currentUserId == null) return {};

    try {
      final doc = await _db.collection('referrals').doc(currentUserId).get();

      if (!doc.exists) {
        return {
          'totalReferrals': 0,
          'totalXpEarned': 0,
          'referredUsers': <String>[],
        };
      }

      final data = doc.data()!;
      return {
        'totalReferrals': data['totalReferrals'] ?? 0,
        'totalXpEarned': data['totalXpEarned'] ?? 0,
        'referredUsers': List<String>.from(data['referredUsers'] ?? []),
      };
    } catch (e) {
      return {};
    }
  }

  // ═══ Apply Referral Code (during signup) ═══
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    if (currentUserId == null) return {'success': false};

    try {
      final userDoc = await _db.collection('users').doc(currentUserId).get();

      if (userDoc.data()?['referredBy'] != null) {
        return {
          'success': false,
          'message': 'You already used a referral code',
        };
      }

      final query = await _db
          .collection('users')
          .where('referralCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return {'success': false, 'message': 'Invalid referral code'};
      }

      final referrerId = query.docs.first.id;

      if (referrerId == currentUserId) {
        return {'success': false, 'message': 'You can\'t use your own code!'};
      }

      await GamificationService().update(
        action: 'apply_referral',
        referralCode: code,
      );

      return {
        'success': true,
        'message': 'Woohoo! You got 100 XP bonus!',
        'xpEarned': 100,
      };
    } catch (e) {
      print('❌ Error applying referral: $e');
      return {'success': false, 'message': 'Something went wrong'};
    }
  }

  // ═══ Get Top Referrers (Leaderboard) ═══
  Future<List<Map<String, dynamic>>> getTopReferrers({int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection('referrals')
          .orderBy('totalReferrals', descending: true)
          .limit(limit)
          .get();

      List<Map<String, dynamic>> leaders = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if ((data['totalReferrals'] ?? 0) == 0) continue;

        final userDoc = await _db.collection('users').doc(doc.id).get();

        if (userDoc.exists) {
          leaders.add({
            'userId': doc.id,
            'name': userDoc.data()?['name'] ?? 'Student',
            'totalReferrals': data['totalReferrals'] ?? 0,
            'totalXpEarned': data['totalXpEarned'] ?? 0,
            'isCurrentUser': doc.id == currentUserId,
          });
        }
      }

      return leaders;
    } catch (e) {
      print('❌ Error loading leaderboard: $e');
      return [];
    }
  }

  // ═══ Get Quiz Questions for a Chapter ═══
  Future<List<Map<String, dynamic>>> getQuizQuestions({
    String board = 'cbse',
    String className = 'class10',
    required String subjectId,
    required String chapterId,
  }) async {
    try {
      print('🎯 Loading quiz for $chapterId');

      final snapshot = await _db
          .collection('content')
          .doc(board)
          .collection(className)
          .doc(subjectId)
          .collection('chapters')
          .doc(chapterId)
          .collection('quiz')
          .get();

      print('📊 Found ${snapshot.docs.length} questions');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error loading quiz: $e');
      return [];
    }
  }

  // ═══ Save Quiz Result ═══
  Future<void> saveQuizResult({
    required String chapterId,
    required int score,
    required int totalQuestions,
    required int timeSpent,
  }) async {
    if (currentUserId == null) return;

    try {
      await _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('quizResults')
          .add({
            'chapterId': chapterId,
            'score': score,
            'totalQuestions': totalQuestions,
            'percentage': (score / totalQuestions) * 100,
            'timeSpent': timeSpent,
            'completedAt': FieldValue.serverTimestamp(),
          });

      // Add XP
      await GamificationService().update(
        action: 'complete_quiz',
        score: score,
        totalQuestions: totalQuestions,
      );
      print('✅ Quiz result saved. +${score * 10} XP');
    } catch (e) {
      print('❌ Error saving quiz result: $e');
    }
  }

  // ═══ Save Generated Paper to History ═══
  Future<void> savePaperToHistory(Map<String, dynamic> paperData) async {
    if (currentUserId == null) return;

    try {
      await _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('paperHistory')
          .add({...paperData, 'createdAt': FieldValue.serverTimestamp()});
      print('✅ Paper saved to history');
    } catch (e) {
      print('❌ Error saving paper history: $e');
    }
  }

  // ═══ Get Paper History ═══
  Future<List<Map<String, dynamic>>> getPaperHistory() async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('paperHistory')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error fetching paper history: $e');
      return [];
    }
  }

  // ═══ Delete Paper from History ═══
  Future<void> deletePaperHistory(String paperId) async {
    if (currentUserId == null) return;

    try {
      await _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('paperHistory')
          .doc(paperId)
          .delete();
      print('✅ Paper deleted from history');
    } catch (e) {
      print('❌ Error deleting paper history: $e');
    }
  }

  Future<void> initializeUserCollections() async {
    if (currentUserId == null) return;

    final userRef = _db.collection('users').doc(currentUserId);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final batch = _db.batch();

    batch.set(_db.collection('userProgress').doc(currentUserId), {
      'uid': currentUserId,
      'subjectCount': 5,
      'completedChapters': 3,
      'totalChapters': 20,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    batch.set(_db.collection('studyPlans').doc(currentUserId), {
      'uid': currentUserId,
      'title': 'Week 1 Study Plan',
      'focus': ['Mathematics', 'Science'],
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_db.collection('chatHistory').doc(currentUserId), {
      'uid': currentUserId,
      'message': 'Welcome to DecaGrade! Start with a quiz or a chapter.',
      'sender': 'assistant',
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.set(userRef.collection('studyProgress').doc('overview'), {
      'subjectCount': 5,
      'completedChapters': 3,
      'totalChapters': 20,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    batch.set(userRef.collection('studyPlans').doc('weekly-plan'), {
      'title': 'Week 1 Study Plan',
      'focus': ['Mathematics', 'Science'],
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(userRef.collection('chatHistory').doc('welcome'), {
      'message': 'Welcome to DecaGrade! Start with a quiz or a chapter.',
      'sender': 'assistant',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getSubjects(
    String board,
    String className,
  ) async {
    return [
      {
        'id': 'math',
        'name': 'Mathematics',
        'icon': '🔢',
        'color': '#4F8EF7',
        'totalChapters': 15,
      },
      {
        'id': 'science',
        'name': 'Science',
        'icon': '🔬',
        'color': '#10B981',
        'totalChapters': 16,
      },
      {
        'id': 'english',
        'name': 'English',
        'icon': '📚',
        'color': '#8B5CF6',
        'totalChapters': 12,
      },
      {
        'id': 'social',
        'name': 'Social Science',
        'icon': '🌍',
        'color': '#F59E0B',
        'totalChapters': 20,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getSubjectsFromDB({
    String board = 'cbse',
    String className = 'class10',
  }) async {
    try {
      final snapshot = await _db
          .collection('content')
          .doc(board)
          .collection(className)
          .get();

      if (snapshot.docs.isEmpty) {
        return _getDefaultSubjects();
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error loading subjects: $e');
      return _getDefaultSubjects();
    }
  }

  List<Map<String, dynamic>> _getDefaultSubjects() {
    return [
      {
        'id': 'math',
        'name': 'Mathematics',
        'icon': '🔢',
        'color': '#8B5CF6',
        'totalChapters': 15,
      },
      {
        'id': 'science',
        'name': 'Science',
        'icon': '🔬',
        'color': '#10B981',
        'totalChapters': 16,
      },
      {
        'id': 'english',
        'name': 'English',
        'icon': '📚',
        'color': '#F59E0B',
        'totalChapters': 12,
      },
      {
        'id': 'social',
        'name': 'Social Science',
        'icon': '🌍',
        'color': '#EC4899',
        'totalChapters': 20,
      },
    ];
  }

  // ═══ Get Today's Daily Quiz ═══
  Future<Map<String, dynamic>?> getTodayDailyQuiz() async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('🔍 Loading daily quiz for: $dateStr');

      final doc = await _db.collection('dailyQuiz').doc(dateStr).get();

      if (!doc.exists) {
        print('⚠️ No daily quiz for today. Loading fallback.');
        final snapshot = await _db.collection('dailyQuiz').limit(1).get();

        if (snapshot.docs.isEmpty) return null;
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return data;
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('❌ Error loading daily quiz: $e');
      return null;
    }
  }

  // ═══ Check if user completed today's quiz ═══
  Future<bool> hasCompletedTodayQuiz() async {
    if (currentUserId == null) return false;

    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final doc = await _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('dailyQuizzes')
          .doc(dateStr)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // ═══ Save Daily Quiz Result ═══
  Future<void> saveDailyQuizResult({
    required int score,
    required int totalQuestions,
    required int timeSpent,
  }) async {
    if (currentUserId == null) return;

    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('dailyQuizzes')
          .doc(dateStr)
          .set({
            'date': dateStr,
            'score': score,
            'totalQuestions': totalQuestions,
            'percentage': (score / totalQuestions * 100),
            'timeSpent': timeSpent,
            'xpEarned': 50 + (score * 10),
            'completedAt': FieldValue.serverTimestamp(),
          });

      await GamificationService().update(
        action: 'complete_daily_quiz',
        score: score,
        totalQuestions: totalQuestions,
      );

      print('✅ Daily quiz saved: $score/$totalQuestions');
    } catch (e) {
      print('❌ Error saving daily quiz: $e');
    }
  }

  // ═══ Get Daily Quiz History ═══
  Future<List<Map<String, dynamic>>> getDailyQuizHistory({
    int limit = 7,
  }) async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('dailyQuizzes')
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ═══ Get Daily Quiz Streak ═══
  Future<int> getDailyQuizStreak() async {
    if (currentUserId == null) return 0;

    try {
      final userDoc = await _db.collection('users').doc(currentUserId).get();
      return userDoc.data()?['dailyQuizStreak'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentBadges() async {
    try {
      final user = await getCurrentUser();
      if (user == null || user.badges.isEmpty) return [];

      final badges = <Map<String, dynamic>>[];
      for (var badgeId in user.badges.take(3)) {
        final doc = await _db.collection('badges').doc(badgeId).get();
        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = doc.id;
          badges.add(data);
        }
      }
      return badges;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLastChapter() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _db.collection('userProgress').doc(currentUserId).get();

      if (!doc.exists) return null;
      final data = doc.data();
      final lastChapter = data?['lastChapter'];
      if (lastChapter is! Map) return null;

      return Map<String, dynamic>.from(lastChapter);
    } catch (e) {
      return null;
    }
  }

  Future<int> getTodayStudyMinutes() async {
    if (currentUserId == null) return 0;
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month}-${today.day}';

      final doc = await _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('daily')
          .doc(dateStr)
          .get();

      if (!doc.exists) return 0;
      return doc.data()?['studyMinutes'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ═══ Save Study Session ═══
  Future<void> saveStudySession({
    required int durationMinutes,
    String? subject,
    String? topic,
  }) async {
    if (currentUserId == null) return;

    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('studySessions')
          .add({
            'date': dateStr,
            'durationMinutes': durationMinutes,
            'subject': subject,
            'topic': topic,
            'timestamp': FieldValue.serverTimestamp(),
          });

      final dayDoc = _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('daily')
          .doc(dateStr);

      await dayDoc.set({
        'date': dateStr,
        'studyMinutes': FieldValue.increment(durationMinutes),
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Study session saved: $durationMinutes min');
    } catch (e) {
      print('❌ Error saving session: $e');
    }
  }

  // ═══ Get Weekly Study Time ═══
  Future<Map<String, int>> getWeeklyStudyTime() async {
    if (currentUserId == null) return {};

    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      final Map<String, int> weekData = {};

      for (int i = 0; i < 7; i++) {
        final date = weekAgo.add(Duration(days: i + 1));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final doc = await _db
            .collection('userProgress')
            .doc(currentUserId)
            .collection('daily')
            .doc(dateStr)
            .get();

        weekData[dateStr] = doc.exists ? (doc.data()?['studyMinutes'] ?? 0) : 0;
      }

      return weekData;
    } catch (e) {
      print('❌ Error: $e');
      return {};
    }
  }

  // ═══ Set Daily Goal ═══
  Future<void> setDailyGoal(int minutes) async {
    if (currentUserId == null) return;
    await _db.collection('users').doc(currentUserId).update({
      'dailyGoal': minutes,
    });
  }

  // ═══ Set Exam Date ═══
  Future<void> setExamDate(String date) async {
    if (currentUserId == null) return;
    await _db.collection('users').doc(currentUserId).update({'examDate': date});
  }

  // ═══ Get Total Study Days ═══
  Future<int> getTotalStudyDays() async {
    if (currentUserId == null) return 0;

    try {
      final snapshot = await _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('daily')
          .get();

      return snapshot.docs
          .where((doc) => (doc.data()['studyMinutes'] ?? 0) > 0)
          .length;
    } catch (e) {
      return 0;
    }
  }

  // ═══ Get chapters for a subject ═══
  Future<List<Map<String, dynamic>>> getChapters({
    String board = 'cbse',
    String className = 'class10',
    required String subjectId,
    bool onlyPublished = true,
  }) async {
    try {
      print('🔍 Loading chapters for: $subjectId');

      Query<Map<String, dynamic>> query = _db
          .collection('content')
          .doc(board)
          .collection(className)
          .doc(subjectId)
          .collection('chapters');

      // Only show published chapters for students
      if (onlyPublished) {
        query = query.where('isPublished', isEqualTo: true);
      }

      query = query.limit(20);

      final snapshot = await query.get();

      print('📊 Found ${snapshot.docs.length} chapters');

      // Sort by chapterNumber if exists
      final chapters = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      chapters.sort((a, b) {
        final aNum = a['chapterNumber'] ?? 999;
        final bNum = b['chapterNumber'] ?? 999;
        return aNum.compareTo(bNum);
      });

      return chapters;
    } catch (e) {
      print('❌ Error loading chapters: $e');
      return [];
    }
  }

  // ═══ Get single chapter details ═══
  Future<Map<String, dynamic>?> getChapterDetail({
    String board = 'cbse',
    String className = 'class10',
    required String subjectId,
    required String chapterId,
  }) async {
    try {
      final doc = await _db
          .collection('content')
          .doc(board)
          .collection(className)
          .doc(subjectId)
          .collection('chapters')
          .doc(chapterId)
          .get();

      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      print('Error loading chapter: $e');
      return null;
    }
  }

  // ═══ Save/Update Chapter (Admin only) ═══
  Future<bool> saveChapter({
    required String subjectId,
    required String chapterId,
    required Map<String, dynamic> data,
    String board = 'cbse',
    String className = 'class10',
  }) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['createdBy'] = currentUserId;

      await _db
          .collection('content')
          .doc(board)
          .collection(className)
          .doc(subjectId)
          .collection('chapters')
          .doc(chapterId)
          .set(data, SetOptions(merge: true));

      print('✅ Chapter saved: $chapterId');
      return true;
    } catch (e) {
      print('❌ Error saving chapter: $e');
      return false;
    }
  }

  // ═══ Delete Chapter (Admin only) ═══
  Future<bool> deleteChapter({
    required String subjectId,
    required String chapterId,
    String board = 'cbse',
    String className = 'class10',
  }) async {
    try {
      await _db
          .collection('content')
          .doc(board)
          .collection(className)
          .doc(subjectId)
          .collection('chapters')
          .doc(chapterId)
          .delete();

      print('✅ Chapter deleted: $chapterId');
      return true;
    } catch (e) {
      print('❌ Error deleting chapter: $e');
      return false;
    }
  }

  // ═══ Toggle Publish Status ═══
  Future<bool> togglePublish({
    required String subjectId,
    required String chapterId,
    required bool isPublished,
    String board = 'cbse',
    String className = 'class10',
  }) async {
    try {
      await _db
          .collection('content')
          .doc(board)
          .collection(className)
          .doc(subjectId)
          .collection('chapters')
          .doc(chapterId)
          .update({
            'isPublished': isPublished,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('✅ Publish status: $isPublished');
      return true;
    } catch (e) {
      print('❌ Error toggling publish: $e');
      return false;
    }
  }

  // ═══ Log Chapter View (Analytics) ═══
  Future<void> logChapterView(String chapterId) async {
    try {
      await _db
          .collection('analytics')
          .doc('chapters')
          .collection('data')
          .doc(chapterId)
          .set({
            'views': FieldValue.increment(1),
            'lastViewed': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Error logging view: $e');
    }
  }

  // ═══ Delete User Account ═══
  Future<bool> deleteUserAccount() async {
    if (currentUserId == null) return false;
    try {
      // Delete user document
      await _db.collection('users').doc(currentUserId).delete();
      // Delete user progress
      await _db.collection('userProgress').doc(currentUserId).delete();
      print('✅ User account deleted');
      return true;
    } catch (e) {
      print('❌ Error deleting user: $e');
      return false;
    }
  }

  // ═══ Get Quiz History ═══
  Future<List<Map<String, dynamic>>> getQuizHistory() async {
    if (currentUserId == null) return [];
    try {
      final snapshot = await _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('quizResults')
          .orderBy('completedAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error loading quiz history: $e');
      return [];
    }
  }

  // ═══ Get All Quiz Results ═══
  Future<List<Map<String, dynamic>>> getAllQuizResults({int? limit}) async {
    if (currentUserId == null) return [];

    try {
      Query<Map<String, dynamic>> query = _db
          .collection('userProgress')
          .doc(currentUserId)
          .collection('quizResults')
          .orderBy('completedAt', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error loading quiz results: $e');
      return [];
    }
  }

  // ═══ Get Subject-wise Performance ═══
  Future<Map<String, Map<String, dynamic>>> getSubjectPerformance() async {
    if (currentUserId == null) return {};

    try {
      final results = await getAllQuizResults();
      final Map<String, Map<String, dynamic>> subjectStats = {};

      for (var result in results) {
        String subject = 'math';

        if (!subjectStats.containsKey(subject)) {
          subjectStats[subject] = {
            'totalQuizzes': 0,
            'totalScore': 0,
            'totalQuestions': 0,
            'totalTime': 0,
          };
        }

        subjectStats[subject]!['totalQuizzes'] =
            (subjectStats[subject]!['totalQuizzes'] as int) + 1;
        subjectStats[subject]!['totalScore'] =
            (subjectStats[subject]!['totalScore'] as num).toInt() +
            ((result['score'] as num?)?.toInt() ?? 0);
        subjectStats[subject]!['totalQuestions'] =
            (subjectStats[subject]!['totalQuestions'] as num).toInt() +
            ((result['totalQuestions'] as num?)?.toInt() ?? 0);
        subjectStats[subject]!['totalTime'] =
            (subjectStats[subject]!['totalTime'] as num).toInt() +
            ((result['timeSpent'] as num?)?.toInt() ?? 0);
      }

      return subjectStats;
    } catch (e) {
      print('❌ Error: $e');
      return {};
    }
  }

  // ═══ Get Overall Stats ═══
  Future<Map<String, dynamic>> getOverallStats() async {
    if (currentUserId == null) return {};

    try {
      final results = await getAllQuizResults();

      if (results.isEmpty) {
        return {
          'totalQuizzes': 0,
          'averageScore': 0.0,
          'totalTime': 0,
          'bestScore': 0,
          'totalCorrect': 0,
          'totalQuestions': 0,
        };
      }

      int totalScore = 0;
      int totalQuestions = 0;
      int totalTime = 0;
      int bestScore = 0;

      for (var result in results) {
        final score = (result['score'] as num?)?.toInt() ?? 0;
        final questions = (result['totalQuestions'] as num?)?.toInt() ?? 0;
        final time = (result['timeSpent'] as num?)?.toInt() ?? 0;
        final percentage = questions > 0 ? (score / questions * 100) : 0;

        totalScore += score;
        totalQuestions += questions;
        totalTime += time;
        if (percentage.toInt() > bestScore) bestScore = percentage.toInt();
      }

      return {
        'totalQuizzes': results.length,
        'averageScore': totalQuestions > 0
            ? (totalScore / totalQuestions * 100)
            : 0.0,
        'totalTime': totalTime,
        'bestScore': bestScore,
        'totalCorrect': totalScore,
        'totalQuestions': totalQuestions,
      };
    } catch (e) {
      print('❌ Error: $e');
      return {};
    }
  }
}
