import 'package:flutter/material.dart';

import '../../config/theme.dart';

enum LegalDocument { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = document == LegalDocument.privacy;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isPrivacy ? 'Privacy Policy' : 'Terms & Conditions'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            isPrivacy
                ? 'DecaGrade Privacy Policy'
                : 'DecaGrade Terms & Conditions',
            style: AppTextStyles.heading1,
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: 26 September 2026',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),
          if (isPrivacy) ..._privacySections else ..._termsSections,
        ],
      ),
    );
  }

  List<Widget> get _privacySections => _sections([
    (
      'Introduction',
      'Welcome to DecaGrade ("we", "our", or "us"). We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application DecaGrade (the "App").',
    ),
    (
      'Information we collect',
      'Account information: When you register, we collect your name, email address, and a secure password. Profile information: We collect your class, board, and selected subjects to personalize your learning experience. Usage and performance data: Firebase Analytics and Firebase Crashlytics collect data about how you interact with the App, such as chapters viewed and features used, and help us detect and fix crashes. Crashlytics does not log personally identifiable information or AI chat prompts. AI interactions: When you use the AI Tutor, your prompts are sent securely to our backend and processed by the Google Gemini API to generate responses. We do not permanently store chat prompt text or use it to train external AI models. Payment information: Premium subscription payment processing is handled securely by Razorpay. We do not store your credit card or banking details on our servers.',
    ),
    (
      'How we use your information',
      'We use information to create and manage your account, personalize your dashboard with relevant study materials, calculate and maintain gamification metrics such as XP and streaks, provide AI tutoring, process premium subscription payments, and improve App stability and user experience.',
    ),
    (
      'Third-party services',
      'Our App relies on third-party services that have their own privacy policies: Firebase (Authentication, Firestore, Analytics, and Crashlytics) at https://firebase.google.com/support/privacy; Google Gemini API at https://policies.google.com/privacy; Cloudinary at https://cloudinary.com/privacy; and Razorpay at https://razorpay.com/privacy/.',
    ),
    (
      'Refund policy',
      'Due to the digital nature of our services, including AI usage and premium content access, purchases of DecaGrade Premium subscriptions are final and non-refundable, except where required by local law. If a technical issue prevents access to purchased features, contact DecaGrade support through the support channel provided with your account or app distribution listing for troubleshooting and potential resolution.',
    ),
    (
      'Data security',
      'We implement industry-standard security measures. Sensitive actions, including XP calculation, streak tracking, and premium entitlement verification, are processed securely on our backend servers to prevent unauthorized manipulation. All data transmission is encrypted.',
    ),
    (
      'Your rights and account deletion',
      'You may access and update your personal information and request deletion. You can permanently delete your DecaGrade account from the App Profile screen. When deletion is completed, we delete your profile, study progress, chat history, and other associated data, subject to records we must retain for legal or payment obligations.',
    ),
    (
      "Children's privacy",
      'The App is designed for students, typically aged 13 and above. We do not knowingly collect personal information from children under 13 without verifiable parental consent. If we become aware that we have collected such information, we will take steps to delete it promptly.',
    ),
    (
      'Changes to this Privacy Policy',
      'We may update this Privacy Policy from time to time. We will post the updated policy in the App and update the last-updated date.',
    ),
    (
      'Contact',
      'If you have questions or concerns about this Privacy Policy or a technical issue with a purchase, contact DecaGrade support through the support channel provided with your account or app distribution listing.',
    ),
  ]);

  List<Widget> get _termsSections => _sections([
    (
      'Using DecaGrade',
      'You must provide accurate account information, protect your sign-in session, and use the service for lawful educational purposes. You are responsible for activity performed through your account.',
    ),
    (
      'Educational content and AI',
      'DecaGrade provides study assistance, not professional advice or a guarantee of examination results. Verify important answers with teachers, textbooks, and official curriculum resources.',
    ),
    (
      'Subscriptions and payments',
      'Premium access is activated after successful payment verification. Prices, billing periods, cancellation, refunds, and payment records are handled through the applicable payment provider and displayed at checkout.',
    ),
    (
      'Acceptable use',
      'Do not abuse, reverse engineer, scrape, disrupt, overload, or attempt to bypass authentication, usage limits, premium controls, or content protections.',
    ),
    (
      'Content ownership',
      'DecaGrade and its licensors retain rights in the app, original content, branding, and software. You retain rights in material you submit, while granting the permissions needed to provide the requested feature.',
    ),
    (
      'Availability and changes',
      'Features may change, be unavailable, or contain errors. We may update these terms and will publish the current version in the app.',
    ),
  ]);

  List<Widget> _sections(List<(String, String)> sections) => [
    for (final section in sections) ...[
      Text(section.$1, style: AppTextStyles.heading2),
      const SizedBox(height: 6),
      Text(section.$2, style: AppTextStyles.bodyMedium),
      const SizedBox(height: 20),
    ],
  ];
}
