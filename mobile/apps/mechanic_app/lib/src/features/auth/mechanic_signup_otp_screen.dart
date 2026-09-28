import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_core/shared_core.dart';

class MechanicSignupOtpScreen extends StatefulWidget {
  final Map<String, dynamic>? extras;
  const MechanicSignupOtpScreen({super.key, this.extras});

  @override
  State<MechanicSignupOtpScreen> createState() =>
      _MechanicSignupOtpScreenState();
}

class _MechanicSignupOtpScreenState extends State<MechanicSignupOtpScreen> {
  static const int _otpLength = 6;
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _focusNodes;
  final _supabaseService = SupabaseService();

  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _timer;

  String get _email => widget.extras?['email']?.toString() ?? '';
  String get _password => widget.extras?['password']?.toString() ?? '';
  String get _name => widget.extras?['name']?.toString() ?? '';
  String get _phone => widget.extras?['phone']?.toString() ?? '';
  String get _specialization =>
      widget.extras?['specialization']?.toString() ?? 'General Service';
  String get _otpCode => _otpControllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _otpControllers =
        List.generate(_otpLength, (index) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (index) => FocusNode());
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_otpCode.length < _otpLength) return;
    if (_email.isEmpty) {
      _showSnackBar('Email is missing. Please go back and try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _supabaseService.verifyEmailOtp(
        email: _email,
        otp: _otpCode,
      );

      final user = response.user ?? _supabaseService.currentUser;
      if (user == null) {
        if (mounted) {
          _showSnackBar('Verification failed. Invalid or expired code.');
        }
        return;
      }

      // If a password was provided in quick signup, set it now
      if (_password.isNotEmpty) {
        try {
          await _supabaseService.setPassword(_password);
        } catch (e) {
          debugPrint('setPassword failed after OTP verify: $e');
        }
      }

      // Sync user profile & metadata
      try {
        await _supabaseService.updateUserProfile(
          data: {
            'role': 'MECHANIC',
            if (_name.isNotEmpty) 'full_name': _name,
            if (_name.isNotEmpty) 'display_name': _name,
            if (_phone.isNotEmpty) 'phone': _phone,
            if (_specialization.isNotEmpty) 'specialization': _specialization,
          },
        );

        // Sync with Spring Boot backend
        await _supabaseService.syncWithBackend(
          role: 'MECHANIC',
          fullName: _name.isNotEmpty ? _name : null,
          phone: _phone.isNotEmpty ? _phone : null,
          specialization: _specialization.isNotEmpty ? _specialization : null,
        );
      } catch (e) {
        debugPrint('Profile setup failed after OTP verify: $e');
      }

      if (!mounted) return;

      _showSnackBar('Mechanic account verified! Welcome.', isError: false);
      context.go('/worker');
    } catch (e) {
      if (mounted) {
        _showSnackBar('Email verification failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendCountdown > 0) return;
    if (_email.isEmpty) return;

    try {
      await _supabaseService.resendEmailOtp(email: _email);
      if (mounted) {
        _showSnackBar('Verification code resent!', isError: false);
        _startCountdown();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to resend code. Please try again.');
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail = _email.isNotEmpty
        ? _email.replaceRange(
            1,
            _email.indexOf('@') > 1 ? _email.indexOf('@') - 1 : 1,
            '***',
          )
        : 'your email';

    return SignUpScaffold(
      children: [
        SignUpHeader(
          step: 2,
          totalSteps: 2,
          title: 'Verify Email',
          subtitle: 'Enter the 6-digit code sent to $maskedEmail',
          onBack: () => context.pop(),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // OTP input boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_otpLength, (i) {
                    return SizedBox(
                      width: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _otpControllers[i],
                          focusNode: _focusNodes[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: GoogleFonts.instrumentSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && i < _otpLength - 1) {
                              _focusNodes[i + 1].requestFocus();
                            } else if (val.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                            if (_otpCode.length == _otpLength) {
                              _handleVerify();
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                SignUpPrimaryButton(
                  label: 'Verify & Enter Workspace',
                  isLoading: _isLoading,
                  onTap: _handleVerify,
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: _resendCountdown == 0 ? _handleResend : null,
                    child: Text(
                      _resendCountdown > 0
                          ? 'Resend code in ${_resendCountdown}s'
                          : 'Resend Code',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _resendCountdown > 0
                            ? Colors.black45
                            : const Color(0xFFFF5D2E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
