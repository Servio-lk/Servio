import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_core/shared_core.dart';

class MechanicSignupEmailScreen extends StatefulWidget {
  const MechanicSignupEmailScreen({super.key});

  @override
  State<MechanicSignupEmailScreen> createState() =>
      _MechanicSignupEmailScreenState();
}

class _MechanicSignupEmailScreenState extends State<MechanicSignupEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _supabaseService = SupabaseService();

  String _selectedSpecialization = 'General Service';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  static const List<String> _specializations = [
    'General Service',
    'Engine Repair',
    'Electrical & Diagnostics',
    'Brakes & Suspension',
    'Transmission & Drivetrain',
    'AC & Climate Control',
    'Body & Paintwork',
    'Hybrid & EV Systems',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleQuickSignup() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_supabaseService.currentSession != null) {
        await _supabaseService.signOut();
      }

      await _supabaseService.requestSignupOtp(
        email: email,
        data: {
          'full_name': name,
          'display_name': name,
          'phone': phone,
          'role': 'MECHANIC',
          'specialization': _selectedSpecialization,
          'signup_flow': 'otp',
        },
      );

      if (!mounted) return;

      _showSnackBar('Verification code sent to $email', isError: false);

      context.push(
        '/signup/otp',
        extra: {
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'specialization': _selectedSpecialization,
          'role': 'MECHANIC',
        },
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Failed to send verification code. Please check your details.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
    return SignUpScaffold(
      children: [
        SignUpHeader(
          step: 1,
          totalSteps: 2,
          title: 'Join as Mechanic',
          subtitle: 'Create your staff account with essential details.',
          onBack: () => context.go('/signin'),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SignUpLabel('FULL NAME *'),
                  const SizedBox(height: 8),
                  SignUpInputField(
                    controller: _nameController,
                    hint: 'e.g. Kasun Perera',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('EMAIL ADDRESS *'),
                  const SizedBox(height: 8),
                  SignUpInputField(
                    controller: _emailController,
                    hint: 'e.g. kasun@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || !EmailValidator.isValid(v.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('PHONE NUMBER *'),
                  const SizedBox(height: 8),
                  SignUpInputField(
                    controller: _phoneController,
                    hint: 'e.g. 0771234567',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (v) {
                      if (v == null || v.length != 10) {
                        return 'Phone number must be exactly 10 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('PRIMARY SPECIALIZATION *'),
                  const SizedBox(height: 8),
                  SignUpDropdownField<String>(
                    value: _selectedSpecialization,
                    hint: 'Select your specialty',
                    items: _specializations
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedSpecialization = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('PASSWORD *'),
                  const SizedBox(height: 8),
                  SignUpPasswordField(
                    controller: _passwordController,
                    hint: 'At least 6 characters',
                    obscure: _obscurePassword,
                    onToggle: () => setState(
                      () => _obscurePassword = !_obscurePassword,
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  const SignUpLabel('CONFIRM PASSWORD *'),
                  const SizedBox(height: 8),
                  SignUpPasswordField(
                    controller: _confirmPasswordController,
                    hint: 'Re-enter your password',
                    obscure: _obscureConfirmPassword,
                    onToggle: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please confirm your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  SignUpPrimaryButton(
                    label: 'Create Account',
                    isLoading: _isLoading,
                    onTap: _handleQuickSignup,
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/signin'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Already have an account? Sign In',
                          style: GoogleFonts.instrumentSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
