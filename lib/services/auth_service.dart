import 'dart:convert';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Map<String, dynamic> _decodeAuthResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      return {};
    }
    return {};
  }

  String _authResponseError(Map<String, dynamic> response, String fallback) {
    final detail = response['detail'];
    return detail is String && detail.isNotEmpty ? detail : fallback;
  }

  Future<void> sendOtp({required String phoneNumber}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.backendBaseUrl}/api/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber}),
    );
    final responseBody = _decodeAuthResponse(response.body);
    if (response.statusCode != 200 || responseBody['success'] != true) {
      throw Exception(
        _authResponseError(responseBody, 'Could not send verification code.'),
      );
    }
  }

  Future<UserCredential> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.backendBaseUrl}/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone_number': phoneNumber, 'otp': otp}),
    );
    final responseBody = _decodeAuthResponse(response.body);
    final customToken = responseBody['custom_token'];
    if (response.statusCode != 200 ||
        responseBody['success'] != true ||
        customToken is! String ||
        customToken.isEmpty) {
      throw Exception(
        _authResponseError(responseBody, 'Could not verify OTP.'),
      );
    }
    return _auth.signInWithCustomToken(customToken);
  }

  Future<bool> needsProfileCompletion(UserCredential credential) async {
    final user = credential.user;
    if (user == null) return false;

    try {
      final profile = await _firestore.collection('users').doc(user.uid).get();
      return !profile.exists;
    } catch (error) {
      developer.log('Phone profile lookup failed: $error');
      return credential.additionalUserInfo?.isNewUser ?? false;
    }
  }

  Future<void> saveUserProfile(String name, String? email, String phone) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final uid = user.uid;
    final data = <String, dynamic>{
      'uid': uid,
      'name': name.trim(),
      'phoneNumber': phone,
      'class': 'Class 10',
      'board': 'CBSE',
      'photoUrl': '',
      'badges': [],
      'dailyGoal': 60,
      'loginMethod': 'phone',
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (email != null && email.trim().isNotEmpty) data['email'] = email.trim();
    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
    try {
      await FirestoreService().initializeUserCollections();
    } catch (error) {
      developer.log('User collection initialization failed: $error');
    }
    await user.updateDisplayName(name.trim());
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) throw Exception('Session expired');

    final response = await http.delete(
      Uri.parse('${ApiConfig.backendBaseUrl}/api/account'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Account deletion failed (${response.statusCode})');
    }
    await _auth.signOut();
  }

  // Sign Up with Email
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String selectedClass,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await result.user!.updateDisplayName(name.trim());

      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'class': selectedClass,
        'board': 'CBSE',
        'photoUrl': '',
        'badges': [],
        'dailyGoal': 60,
        'loginMethod': 'email',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirestoreService().initializeUserCollections();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'Password is too weak';
      if (e.code == 'email-already-in-use') return 'Email already registered';
      if (e.code == 'invalid-email') return 'Invalid email address';
      return e.message ?? 'Signup failed';
    } catch (e) {
      return 'Something went wrong. Try again';
    }
  }

  // Sign In with Email
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No account found';
      if (e.code == 'wrong-password') return 'Incorrect password';
      if (e.code == 'invalid-email') return 'Invalid email';
      if (e.code == 'invalid-credential') return 'Invalid email or password';
      return e.message ?? 'Login failed';
    } catch (e) {
      return 'Something went wrong. Try again';
    }
  }

  // Google Sign In
  Future<String?> signInWithGoogle() async {
    try {
      // Force sign out first to prevent cached account issues
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return 'Sign in cancelled';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Authenticate with Firebase
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      try {
        // Run Firestore creation safely
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'uid': userCredential.user!.uid,
                'name': userCredential.user!.displayName ?? 'Student',
                'email': userCredential.user!.email,
                'class': 'Class 10', // Hardcoded to Class 10
                'board': 'CBSE',
                'photoUrl': userCredential.user!.photoURL ?? '',
                'loginMethod': 'google',
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      } catch (firestoreError) {
        // If Firestore fails (e.g. offline cache delay), DO NOT block the user from logging in.
        developer.log(
          'Firestore profile creation delayed/failed: $firestoreError',
        );
      }

      return null; // Always return success if Firebase Auth succeeded
    } catch (e) {
      developer.log('Google sign in fatal error: $e');
      return 'Failed to sign in with Google. Please try again.';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Reset Password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } catch (e) {
      return 'Failed to send reset email';
    }
  }
}
