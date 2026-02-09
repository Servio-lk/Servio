import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Implement sign in logic
      context.go('/home');
    }
  }

  void _handleGoogleSignIn() {
    // TODO: Implement Google sign in
    context.go('/home');
  }

  void _handleFacebookSignIn() {
    // TODO: Implement Facebook sign in
    context.go('/home');
  }

  void _handleForgotPassword() {
    // TODO: Implement forgot password
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
                            const Text(
                              'Welcome Back to Servio',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Instrument Sans',
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Log in to manage your vehicle's service.",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                                fontFamily: 'Instrument Sans',
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
                                  color: const Color(0xFFFF5D2E),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  boxShadow: [
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
                                    onTap: _handleSignIn,
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Center(
                                        child: Text(
                                          'Log In',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            fontFamily: 'Instrument Sans',
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
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black.withOpacity(0.7),
                                      fontFamily: 'Instrument Sans',
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
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black.withOpacity(0.7),
                                      fontFamily: 'Instrument Sans',
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontFamily: 'Instrument Sans',
                  ),
                  decoration: InputDecoration(
                    hintText: label,
                    hintStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black.withOpacity(0.5),
                      fontFamily: 'Instrument Sans',
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Instrument Sans',
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
