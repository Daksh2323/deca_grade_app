import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Separated StreamBuilder for premium status to avoid rebuilding entire parent widget
/// ⚡ OPTIMIZATION: Scoped listener prevents full screen rebuilds
class PremiumStatusListener extends StatelessWidget {
  final Widget Function(BuildContext context, bool isPremium) builder;

  const PremiumStatusListener({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return builder(context, false);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return builder(context, false);
        }

        final data = snapshot.data?.data();
        final expiryValue = data?['expiryDate'];
        final expiryDate = expiryValue is Timestamp
            ? expiryValue.toDate()
            : expiryValue is DateTime
            ? expiryValue
            : null;
        final isActive =
            expiryDate == null || expiryDate.isAfter(DateTime.now());
        final isPremium =
            isActive && (data?['isPro'] == true || data?['isUltimate'] == true);

        return builder(context, isPremium);
      },
    );
  }
}

/// Extended version that provides full user data for detailed membership info
/// ⚡ OPTIMIZATION: Used by profile screen to avoid re-parsing user data
class PremiumStatusListenerWithData extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    bool isPremium,
    Map<String, dynamic> userData,
    DateTime? expiryDate,
  )
  builder;

  const PremiumStatusListenerWithData({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return builder(context, false, {}, null);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return builder(context, false, {}, null);
        }

        final data = snapshot.data?.data() ?? {};
        final expiryValue = data['expiryDate'];
        final expiryDate = expiryValue is Timestamp
            ? expiryValue.toDate()
            : expiryValue is DateTime
            ? expiryValue
            : null;
        final isActive =
            expiryDate == null || expiryDate.isAfter(DateTime.now());
        final isPremium =
            isActive && (data['isPro'] == true || data['isUltimate'] == true);

        return builder(context, isPremium, data, expiryDate);
      },
    );
  }
}
