import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/supabase_service.dart';
import '../../core/utils/email_validator.dart';
import 'signup_widgets.dart';

class SignUpStep1Screen extends StatefulWidget {
  final Map<String, dynamic>? extras;

  const SignUpStep1Screen({super.key, this.extras});

  @override
  State<SignUpStep1Screen> createState() => _SignUpStep1ScreenState();
}

class _SignUpStep1ScreenState extends State<SignUpStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final extras = widget.extras;
    if (extras == null) return;

    _nameController.text = (extras['name'] as String?) ?? '';
    _emailController.text = (extras['email'] as String?) ?? '';
    _phoneController.text = (extras['phone'] as String?) ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      // Start sign-up from a clean auth state to avoid carrying a previous user.
      if (_supabaseService.currentSession != null) {
        await _supabaseService.signOut();
      }

      // Use /auth/v1/otp instead of /auth/v1/signup to avoid strict email caps.
      await _supabaseService.requestSignupOtp(
        email: email,
        data: {
          'full_name': name,
          'display_name': name,
          'phone': phone,
          'signup_flow': 'otp',
        },
      );

      if (!mounted) return;

      _showSnackBar(
        'Verification code sent. Please check your email.',
        isError: false,
      );

      context.go(
        '/signup/otp',
        extra: {
          ...?widget.extras,
          'email': email,
          'name': name,
          'phone': phone,
          'password': password,
        },
      );
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Sign up failed. Please try again.';
        final errorStr = e.toString();

        if (errorStr.contains('User already registered')) {
          errorMessage = 'An account with this email already exists.';
        } else if (errorStr.contains('For security purposes, you can only request this after')) {
          errorMessage = 'Please wait 60 seconds before requesting a new code.';
        } else if (errorStr.contains('Network') ||
            errorStr.contains('SocketException') ||
            errorStr.contains('Failed host lookup') ||
            errorStr.contains('ClientException') ||
            errorStr.contains('AuthRetryableFetchException')) {
          errorMessage =
              'Unable to connect to the server. Please check your internet connection.';
        } else if (errorStr.contains('rate limit') ||
            errorStr.contains('429')) {
          errorMessage =
              'Too many attempts. Please wait a moment and try again.';
        }

        _showSnackBar(errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    return SignUpScaffold(
      children: [
        // Header
        SignUpHeader(
          step: 1,
          title: "Let's get you on the road",
          subtitle:
              "Create your account to easily book services and track your vehicle's health.",
          onBack: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/signin');
            }
          },
        ),
        const SizedBox(height: 8),

        // Form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SignUpLabel('Full Name:'),
                  const SizedBox(height: 8),
                  SignUpInputField(
                    controller: _nameController,
                    hint: 'Chamira Fernando',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('Email Address:'),
                  const SizedBox(height: 8),
                  SignUpInputField(
                    controller: _emailController,
                    hint: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!EmailValidator.isValid(v)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('Phone Number:'),
                  const SizedBox(height: 8),
                  SignUpInputField(
                    controller: _phoneController,
                    hint: '07X XXX XXXX',
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      
                      // Remove +, spaces, and dashes for length validation
                      final digitsOnly = v.replaceAll(RegExp(r'[\+\s\-]'), '');
                      if (digitsOnly.length < 10) {
                        return 'Phone number must have at least 10 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const SignUpHelperText(
                    "We'll only use this to send you service updates and urgent alerts.",
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('Password:'),
                  const SizedBox(height: 8),
                  SignUpPasswordField(
                    controller: _passwordController,
                    obscure: _obscurePassword,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (v.length < 8) {
                        return 'Minimum 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const SignUpHelperText('Minimum 8 characters.'),
                  const SizedBox(height: 24),

                  // Already have account link
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/signin'),
                      child: Text(
                        'Already have an account? Sign In',
                        style: GoogleFonts.instrumentSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withValues(alpha: 0.7),
                          height: 22 / 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SignUpPrimaryButton(
            label: 'Create Account',
            onTap: _handleCreateAccount,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }
}
