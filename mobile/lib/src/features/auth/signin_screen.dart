import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/supabase_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        _showSnackBar('Please enter your email and password.');
        return;
      }

      setState(() => _isLoading = true);

      try {
        print('Attempting to sign in with email: $email');
        final response = await _supabaseService.signInWithEmail(
          email: email,
          password: password,
        );

        print('Sign in response: ${response.user?.id}');

        if (response.user != null && mounted) {
          print('Sign in successful!');
          _showSnackBar('Welcome back!', isError: false);
          context.go('/home');
        } else if (mounted) {
          print('Sign in failed: No user returned');
          _showSnackBar('Login failed. Please check your credentials.');
        }
      } catch (e) {
        print('Sign in error: $e');
        if (mounted) {
          String errorMessage = 'Invalid email or password. Please try again.';

          // Check for specific error types
          if (e.toString().contains('Invalid login credentials')) {
            errorMessage = 'Invalid email or password.';
          } else if (e.toString().contains('Email not confirmed')) {
            errorMessage = 'Please verify your email address first.';
          } else if (e.toString().contains('Network')) {
            errorMessage = 'Network error. Please check your connection.';
          }

          _showSnackBar(errorMessage);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final success = await _supabaseService.signInWithGoogle();
      if (success && mounted) {
        _showSnackBar('Signed in with Google!', isError: false);
        context.go('/home');
      } else if (mounted) {
        _showSnackBar('Google sign-in cancelled or failed.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to sign in with Google.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);

    try {
      final success = await _supabaseService.signInWithFacebook();
      if (success && mounted) {
        _showSnackBar('Signed in with Facebook!', isError: false);
        context.go('/home');
      } else if (mounted) {
        _showSnackBar('Facebook sign-in cancelled or failed.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to sign in with Facebook.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Please enter a valid email address first.');
      return;
    }

    try {
      await _supabaseService.resetPasswordForEmail(email);
      if (mounted) {
        _showSnackBar(
          'Password reset email sent! Check your inbox.',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to send password reset email.');
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
                              onTap: () => context.go('/welcome'),
                              child: const Center(
                                child: Icon(Icons.close, size: 24, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Welcome Message
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              'Welcome Back to Servio',
                              style: GoogleFonts.instrumentSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Log in to manage your vehicle's service.",
                              style: GoogleFonts.instrumentSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                height: 22 / 16,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
                            // Log In Button
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
                                            color: const Color(0xFFFF5D2E).withOpacity(0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: _isLoading ? null : _handleSignIn,
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Center(
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                'Log In',
                                                style: GoogleFonts.instrumentSans(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
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
                            // Forgot Password
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: GestureDetector(
                                  onTap: _handleForgotPassword,
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.instrumentSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black.withOpacity(0.7),
                                      decoration: TextDecoration.underline,
                                      height: 22 / 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Don't have account
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: GestureDetector(
                                  onTap: () => context.go('/signup'),
                                  child: Text(
                                    "Don't have an account? Sign Up",
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
                                    padding: EdgeInsets.symmetric(horizontal: 8),
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
                            // Google Login Button
                            _buildSocialLoginButton(
                              label: 'Log In with Google',
                              icon: const Icon(
                                Icons.g_mobiledata,
                                size: 24,
                                color: Colors.black,
                              ),
                              onTap: _handleGoogleSignIn,
                            ),
                            const SizedBox(height: 16),
                            // Facebook Login Button
                            _buildSocialLoginButton(
                              label: 'Log In with Facebook',
                              icon: const Icon(
                                Icons.facebook,
                                size: 24,
                                color: Color(0xFF1877F2),
                              ),
                              onTap: _handleFacebookSignIn,
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
                  obscureText: isPassword && !_isPasswordVisible,
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
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
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
