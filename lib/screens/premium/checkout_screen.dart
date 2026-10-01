import 'dart:async';

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/analytics_service.dart';
import '../../services/firestore_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final Razorpay _razorpay;
  String _selectedPlan = 'Pro Monthly';
  int _selectedAmount = 4900;
  bool _isProcessing = false;
  bool _paymentVerificationStarted = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    unawaited(AnalyticsService.instance.logPremiumUpgradeViewed());
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _selectPlan(String plan, int amount) {
    setState(() {
      _selectedPlan = plan;
      _selectedAmount = amount;
    });
  }

  Future<void> _openRazorpay() async {
    setState(() => _isProcessing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Please sign in again before upgrading.');
      }
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token unavailable.');
      }
      final response = await http.post(
        Uri.parse('${ApiConfig.backendBaseUrl}/api/payments/create-order'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': _selectedAmount,
          'currency': 'INR',
          'receipt': user.uid,
          'plan': _selectedPlan,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception(_backendError(response));
      }
      final order = jsonDecode(response.body) as Map<String, dynamic>;
      final keyId = (order['key_id'] as String?) ?? ApiConfig.razorpayKeyId;
      if (keyId.isEmpty) {
        throw Exception('Razorpay public key is not configured.');
      }
      final contact = user.phoneNumber?.replaceAll(RegExp(r'\D'), '');
      final prefillContact = contact != null && contact.length == 10
          ? contact
          : '9999999999';
      _razorpay.open({
        'key': keyId,
        'amount': order['amount'].toString(),
        'currency': 'INR',
        'order_id': order['order_id'],
        'name': 'DecaGrade',
        'description': 'Premium Subscription',
        'prefill': {
          'contact': prefillContact,
          'email': user.email?.isNotEmpty == true
              ? user.email!
              : 'test@decagrade.com',
        },
        'theme': {'color': '#4F46E5'},
        'config': {
          'display': {
            'blocks': {
              'upi': {
                'name': 'Pay by UPI',
                'instruments': [
                  {'method': 'upi'},
                ],
              },
            },
            'hide': <String>[],
            'sequence': ['block.upi'],
            'preferences': {'show_default_blocks': true},
          },
        },
      });
    } catch (error) {
      if (mounted) setState(() => _isProcessing = false);
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_paymentVerificationStarted) return;
    _paymentVerificationStarted = true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showError('Please sign in again before upgrading.');
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token unavailable.');
      }
      http.Response? verification;
      Object? lastError;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          verification = await http
              .post(
                Uri.parse(
                  '${ApiConfig.backendBaseUrl}/api/payments/verify-payment',
                ),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'razorpay_payment_id': response.paymentId,
                  'razorpay_order_id': response.orderId,
                  'razorpay_signature': response.signature,
                }),
              )
              .timeout(const Duration(seconds: 15));
          if (verification.statusCode == 200) break;
          lastError = Exception(_backendError(verification));
        } catch (error) {
          lastError = error;
        }
        if (attempt < 2) {
          await Future<void>.delayed(Duration(seconds: attempt + 1));
        }
      }
      if (verification?.statusCode != 200) {
        throw lastError ?? Exception('Activation server did not respond.');
      }
      await _firestoreService.getCurrentUser();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment received. Activation failed: ${_errorMessage(error)}',
            ),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Activate',
              textColor: Colors.white,
              onPressed: () => _handlePaymentSuccess(response),
            ),
          ),
        );
      }
    } finally {
      _paymentVerificationStarted = false;
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) setState(() => _isProcessing = false);
    final message = response.code == 0
        ? 'Payment cancelled.'
        : 'Payment failed: ${response.message ?? 'Please try again.'}';
    _showError(message);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) setState(() => _isProcessing = false);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  String _backendError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (_) {}
    return 'Payment service error (${response.statusCode}).';
  }

  String _errorMessage(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('DecaGrade Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.warning,
                    size: 54,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Unlock DecaGrade Premium',
                    style: AppTextStyles.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Study without limits and make every session count.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildBenefits(),
            const SizedBox(height: 24),
            Text('Choose your plan', style: AppTextStyles.heading2),
            const SizedBox(height: 12),
            _buildPlanCard(
              'DecaGrade Pro',
              '₹49/month',
              '₹799/year',
              Icons.auto_awesome_rounded,
              [('Pro Monthly', 4900), ('Pro Yearly', 79900)],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _openRazorpay,
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(
                  _isProcessing
                      ? 'Opening secure checkout...'
                      : 'Upgrade Now - ₹${_selectedAmount ~/ 100}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Payments processed securely by Razorpay',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    const benefits = [
      'Unlimited AI Tutor conversations',
      'Premium PDFs and PYQs',
      'Ad-free study experience',
      'Priority access to mock tests',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: benefits
            .map(
              (benefit) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(benefit, style: AppTextStyles.bodyLarge),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPlanCard(
    String name,
    String monthly,
    String yearly,
    IconData icon,
    List<(String, int)> options,
  ) {
    final isSelected = _selectedPlan.startsWith(name);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.warning : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.18),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.heading2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              if (name == 'DecaGrade Pro')
                const Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOption(options[0].$1, monthly, options[0].$2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOption(
                  options[1].$1,
                  yearly,
                  options[1].$2,
                  badge: 'Save ₹389',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String plan, String price, int amount, {String? badge}) {
    final selected = _selectedPlan == plan;
    return InkWell(
      onTap: () => _selectPlan(plan, amount),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(price, style: AppTextStyles.heading3)),
                if (badge != null)
                  Text(
                    badge,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.contains('Yearly') ? 'Save ₹389' : 'Flexible billing',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
