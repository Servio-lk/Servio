import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/supabase_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();

      setState(() => _isLoading = true);

      try {
        // TODO: Implement sign up logic with _supabaseService
        context.go('/home');
      } catch (e) {
        if (mounted) {
          _showSnackBar('Sign up failed. Please try again.');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);

    try {
      final success = await _supabaseService.signInWithGoogle();
      if (success && mounted) {
        _showSnackBar('Signed up with Google!', isError: false);
        context.go('/home');
      } else if (mounted) {
        _showSnackBar('Google sign-up cancelled or failed.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to sign up with Google.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFacebookSignUp() async {
    setState(() => _isLoading = true);

    try {
      final success = await _supabaseService.signInWithFacebook();
      if (success && mounted) {
        _showSnackBar('Signed up with Facebook!', isError: false);
        context.go('/home');
      } else if (mounted) {
        _showSnackBar('Facebook sign-up cancelled or failed.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to sign up with Facebook.');
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
    return Scaffold(
      body: Stack(
        children: [
          // Background with overlay
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFB),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),
          // Bottom sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Grabber
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCFCFCF),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    // Close button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Material(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => context.go('/signin'),
                              child: const Center(
                                child: Icon(
                                  Icons.close,
                                  size: 24,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Form Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            // Title
                            Text(
                              'Create Your Account',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Subtitle
                            Text(
                              'Sign up to get started with Servio.',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                height: 22 / 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Name Input
                            _buildInputField(
                              controller: _nameController,
                              label: 'Full Name',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 4),
                            // Email Input
                            _buildInputField(
                              controller: _emailController,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 4),
                            // Password Input
                            _buildInputField(
                              controller: _passwordController,
                              label: 'Password',
                              isPassword: true,
                              passwordVisible: _isPasswordVisible,
                              onToggleVisibility: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 4),
                            // Confirm Password Input
                            _buildInputField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              isPassword: true,
                              passwordVisible: _isConfirmPasswordVisible,
                              onToggleVisibility: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Sign Up Button
                            SizedBox(
                              width: double.infinity,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: _isLoading
                                      ? const Color(0xFFFF5D2E).withOpacity(0.6)
                                      : const Color(0xFFFF5D2E),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  boxShadow: _isLoading
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFF5D2E,
                                            ).withOpacity(0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: _isLoading ? null : _handleSignUp,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                'Sign Up',
                                                style:
                                                    GoogleFonts.instrumentSans(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Already have account
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: GestureDetector(
                                  onTap: () => context.go('/signin'),
                                  child: Text(
                                    'Already have an account? Sign In',
                                    style: GoogleFonts.instrumentSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black.withOpacity(0.7),
                                      height: 22 / 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Divider with "or"
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.black.withOpacity(0.1),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                        fontFamily: 'Instrument Sans',
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.black.withOpacity(0.1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Google Sign Up Button
                            _buildSocialLoginButton(
                              label: 'Sign Up with Google',
                              icon: Image.asset(
                                'assets/icons/google.png',
                                width: 24,
                                height: 24,
                              ),
                              onTap: _handleGoogleSignUp,
                            ),
                            const SizedBox(height: 16),
                            // Facebook Sign Up Button
                            _buildSocialLoginButton(
                              label: 'Sign Up with Facebook',
                              icon: Image.asset(
                                'assets/icons/facebook.png',
                                width: 24,
                                height: 24,
                              ),
                              onTap: _handleFacebookSignUp,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool passwordVisible = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 59),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: isPassword && !passwordVisible,
                  style: GoogleFonts.instrumentSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: label,
                    hintStyle: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  validator: validator,
                ),
              ),
              if (isPassword)
                IconButton(
                  icon: Icon(
                    passwordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: 20,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  onPressed: onToggleVisibility,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFE7DF)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.instrumentSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
