import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/duolingo_button.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _authService = AuthService();
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _isLoading = false;
  bool _started = false;
  String _phone = '+91';
  String _phoneNumber = '';

  String get _code => _controllers.map((controller) => controller.text).join();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is Map) {
        _phone = arguments['phone'] as String? ?? '+91';
        _phoneNumber =
            arguments['phoneNumber'] as String? ?? _digitsOnly(_phone);
      } else if (arguments is String) {
        _phone = arguments;
        _phoneNumber = _digitsOnly(_phone);
      }
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) _secondsRemaining--;
        if (_secondsRemaining == 0) _timer?.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.length != 6) return;
    if (_phoneNumber.length != 10) {
      _showError('Verification session expired. Request a new code.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final credential = await _authService.verifyOtp(
        phoneNumber: _phoneNumber,
        otp: _code,
      );
      if (!mounted || credential.user == null) return;
      final needsProfile = await _authService.needsProfileCompletion(
        credential,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        needsProfile ? '/profile-completion' : '/home',
        (_) => false,
        arguments: credential.user!.phoneNumber ?? _phone,
      );
    } catch (error) {
      if (mounted) {
        _showError(_friendlyOtpError(error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    if (_isLoading || _phoneNumber.length != 10) return;
    setState(() => _isLoading = true);
    try {
      await _authService.sendOtp(phoneNumber: _phoneNumber);
      if (mounted) _startTimer();
    } catch (error) {
      if (mounted) {
        _showError(_friendlyOtpError(error));
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

  String _friendlyOtpError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid') ||
        message.contains('incorrect') ||
        message.contains('expired') ||
        message.contains('otp')) {
      return 'Invalid OTP, please try again.';
    }
    if (message.contains('timeout') ||
        message.contains('socket') ||
        message.contains('connection')) {
      return 'Unable to verify OTP. Check your internet connection.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _digitsOnly(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : digits;
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
                Icons.lock_outline_rounded,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Enter Verification Code 🔐',
                style: AppTextStyles.displayLarge,
              ),
              const SizedBox(height: 8),
              Text('Sent to $_phone', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, _buildBox),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: _secondsRemaining == 0 && !_isLoading
                      ? _resend
                      : null,
                  child: Text(
                    _secondsRemaining == 0
                        ? 'Resend OTP'
                        : 'Resend code in 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _secondsRemaining == 0
                          ? AppColors.primary
                          : AppColors.textDisabled,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ).animate(target: _secondsRemaining == 0 ? 1 : 0).fadeIn().scale(),
              DuolingoButton(
                width: double.infinity,
                height: 54,
                label: 'Verify & Continue',
                color: AppColors.primary,
                darkColor: AppColors.primaryDark,
                icon: Icons.arrow_forward_rounded,
                isLoading: _isLoading,
                onPressed:
                    _isLoading || _code.length != 6 || _phoneNumber.length != 10
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        _verify();
                      },
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

  Widget _buildBox(int index) {
    return SizedBox(
      width: 46,
      height: 58,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }
}
