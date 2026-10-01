import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'error_state.dart';
import 'loading_widget.dart';
import 'states.dart';

class PremiumContentGate extends StatelessWidget {
  const PremiumContentGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const UnauthorizedStateWidget();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'We could not verify your premium access.',
          );
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
        return isPremium ? child : _lockedState(context);
      },
    );
  }

  Widget _lockedState(BuildContext context) {
    return const PremiumLockedWidget();
  }
}
