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
  final int _otpLength = 6;
  late List<TextEditingController> _otpControllers;
  late List<FocusNode> _focusNodes;
  final _supabaseService = SupabaseService();

  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _timer;

  String get _email => widget.extras?['email']?.toString() ?? '';
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

      final user = response.user;
      if (user == null) {
        if (mounted) {
          _showSnackBar('Verification failed. Invalid or expired code.');
        }
        return;
      }

      // Sync profile
      try {
        final registeredMechanic =
            await _supabaseService.getActiveMechanicByEmail(_email);
        if (registeredMechanic != null) {
          await _supabaseService.syncMechanicProfile(
            user: user,
            mechanic: registeredMechanic,
          );
        }
      } catch (e) {
        debugPrint('Profile setup failed after OTP verify: $e');
      }

      if (!mounted) return;

      _showSnackBar('Email verified! Redirecting to workspace...',
          isError: false);
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

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Email',
                style: GoogleFonts.instrumentSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "We sent a $_otpLength-digit code to $maskedEmail. Enter it below.",
                style: GoogleFonts.instrumentSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 22 / 16,
                ),
              ),
              const SizedBox(height: 32),

              // OTP Boxes
              SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_otpLength, (i) {
                    return SizedBox(
                      width: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.black.withOpacity(0.1)),
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
                            if (value.isNotEmpty &&
                                i == _otpLength - 1 &&
                                _otpCode.length == _otpLength) {
                              _handleVerify();
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 32),

              // Resend text
              Center(
                child: GestureDetector(
                  onTap: _resendCountdown == 0 ? _handleResend : null,
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.instrumentSans(
                        fontSize: 14,
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
                            fontSize: 14,
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
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 59,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5D2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: _isLoading ? 0 : 8,
                    shadowColor: const Color(0xFFFF5D2E).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verify & Continue',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
