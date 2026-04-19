import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthResponse;

import '../../core/services/supabase_service.dart';
import 'signup_widgets.dart';

class SignUpOtpScreen extends StatefulWidget {
  final Map<String, dynamic>? extras;

  const SignUpOtpScreen({super.key, this.extras});

  @override
  State<SignUpOtpScreen> createState() => _SignUpOtpScreenState();
}

class _SignUpOtpScreenState extends State<SignUpOtpScreen> {
  static const int _otpLength = 6;

  final _supabaseService = SupabaseService();
  final List<TextEditingController> _otpControllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _timer;
  late String _email;
  late String _password;

  @override
  void initState() {
    super.initState();
    _email = (widget.extras?['email'] as String?) ?? '';
    _password = (widget.extras?['password'] as String?) ?? '';
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    if (_email.isEmpty) {
      _showSnackBar('Email is missing. Please go back and try again.');
      return;
    }

    final code = _otpCode;
    if (code.length < _otpLength) {
      _showSnackBar('Please enter the full $_otpLength-digit code.');
      return;
    }

    setState(() => _isLoading = true);

    AuthResponse response;
    try {
      response = await _supabaseService.verifyEmailOtp(
        email: _email,
        otp: code,
      );
    } catch (e) {
      if (mounted) {
        String msg = 'Invalid code. Please try again.';
        final s = e.toString();
        if (s.contains('Token has expired')) {
          msg = 'Code has expired. Please request a new one.';
        }
        _showSnackBar(msg);
      }
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // OTP login creates/opens a session; set password so future login can use email+password.
      if (response.user != null && _password.isNotEmpty) {
        await _supabaseService.setPassword(_password);
      }

      final user = response.user;
      if (user == null) {
        throw Exception('No authenticated user found after OTP verification.');
      }

      final name = (widget.extras?['name'] as String?)?.trim() ?? '';
      final phone = (widget.extras?['phone'] as String?)?.trim() ?? '';

      await _supabaseService.client.from('profiles').upsert({
        'id': user.id,
        'email': _email,
        if (name.isNotEmpty) 'full_name': name,
        if (phone.isNotEmpty) 'phone': phone,
      }, onConflict: 'id');

      final profileRow = await _supabaseService.client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (profileRow == null) {
        throw Exception('Profile setup failed for the authenticated user.');
      }

      if (!mounted) return;

      _showSnackBar('Email verified!', isError: false);
      context.go('/signup/vehicle', extra: widget.extras);
    } catch (e) {
      if (mounted) {
        final s = e.toString();
        if (s.contains('row-level security policy') ||
            s.contains('permission denied') ||
            s.contains('42501')) {
          _showSnackBar(
            'Email verified, but profile permissions are blocked. Please run the profiles RLS migration.',
          );
        } else {
          _showSnackBar(
            'Email verified, but profile setup failed. Please try again.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendCountdown > 0) return;
    if (_email.isEmpty) {
      _showSnackBar('Email is missing. Please go back and try again.');
      return;
    }

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
        // Header
        SignUpHeader(
          step: 2,
          title: 'Check your inbox',
          subtitle:
              'We sent a $_otpLength-digit code to $maskedEmail. Enter it below to verify your account.',
          onBack: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/signup', extra: widget.extras);
            }
          },
        ),
        const SizedBox(height: 8),

        // OTP Input + Resend
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                // OTP digit boxes
                SizedBox(
                  width: 320,
                  height: 64,
                  child: Row(
                    children: List.generate(_otpLength, (i) {
                      return [
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE7DF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white),
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
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && i < _otpLength - 1) {
                                _focusNodes[i + 1].requestFocus();
                              } else if (value.isEmpty && i > 0) {
                                _focusNodes[i - 1].requestFocus();
                              }
                              // Auto-submit on last digit
                              if (value.isNotEmpty &&
                                  i == _otpLength - 1 &&
                                  _otpCode.length == _otpLength) {
                                _handleVerify();
                              }
                            },
                          ),
                        ),
                      ),
                      ];
                    }).expand((widgets) => widgets).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Resend text
                GestureDetector(
                  onTap: _resendCountdown == 0 ? _handleResend : null,
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.instrumentSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 16 / 12,
                      ),
                      children: [
                        const TextSpan(text: "Didn't get the code? "),
                        TextSpan(
                          text: _resendCountdown > 0
                              ? 'Resend it (${_resendCountdown.toString().padLeft(2, '0')}s)'
                              : 'Resend it',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _resendCountdown > 0
                                ? const Color(0xFF8A8A8A)
                                : const Color(0xFFFF5D2E),
                            decoration: TextDecoration.underline,
                            height: 16 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Verify button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SignUpPrimaryButton(
            label: 'Verify & Continue',
            onTap: _handleVerify,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }
}
