import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/duolingo_button.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final _mobileController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    HapticFeedback.mediumImpact();
    final mobile = _mobileController.text.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
      _showError('Enter exactly 10 digits');
      return;
    }

    setState(() => _isLoading = true);
    final phone = '+91$mobile';
    try {
      await _authService.sendOtp(phoneNumber: mobile);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/otp-verification',
        arguments: {'phone': phone, 'phoneNumber': mobile},
      );
    } catch (error) {
      if (mounted) {
        _showError(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.phone_android_rounded,
                size: 52,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text('Login with Mobile 📱', style: AppTextStyles.displayLarge),
              const SizedBox(height: 8),
              Text(
                "We'll send a secure 6-digit code to your number.",
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 38),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _mobileController,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        '+91',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    prefixIconConstraints: BoxConstraints(minWidth: 58),
                    hintText: 'Enter 10-digit mobile number',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              DuolingoButton(
                width: double.infinity,
                height: 54,
                label: 'Send OTP',
                loadingLabel: 'Sending Secure Code...',
                color: AppColors.primary,
                darkColor: AppColors.primaryDark,
                icon: Icons.sms_outlined,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _sendOtp,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Made with 💙 in India',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
