import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  UserService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<Map<String, dynamic>> checkAndResetDailyLimit() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return {'isPro': false, 'isUltimate': false, 'dailyAiCount': 0};
    }

    final userDoc = _firestore.collection('users').doc(uid);
    final snapshot = await userDoc.get();
    if (!snapshot.exists) {
      return {
        'uid': uid,
        'isPro': false,
        'isUltimate': false,
        'dailyAiCount': 0,
      };
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    final lastResetValue = data['lastAiResetDate'];
    final lastReset = lastResetValue is Timestamp
        ? lastResetValue.toDate()
        : lastResetValue is DateTime
        ? lastResetValue
        : null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var dailyAiCount = (data['dailyAiCount'] as num?)?.toInt() ?? 0;

    if (lastReset == null || lastReset.isBefore(today)) dailyAiCount = 0;

    final expiryValue = data['expiryDate'];
    final expiryDate = expiryValue is Timestamp
        ? expiryValue.toDate()
        : expiryValue is DateTime
        ? expiryValue
        : null;
    final isActive = expiryDate == null || expiryDate.isAfter(now);

    return {
      'uid': uid,
      'isPro': isActive && data['isPro'] == true,
      'isUltimate': isActive && data['isUltimate'] == true,
      'dailyAiCount': dailyAiCount,
    };
  }
}
