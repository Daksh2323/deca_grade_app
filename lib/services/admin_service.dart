import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    if (currentUserId == null) return false;

    try {
      final doc = await _db.collection('admins').doc(currentUserId).get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get admin details
  Future<Map<String, dynamic>?> getAdminDetails() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _db.collection('admins').doc(currentUserId).get();

      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      return null;
    }
  }
}
