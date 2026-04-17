import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Data model for each onboarding page
// ---------------------------------------------------------------------------
class _OnboardingPageData {
  final String image;
  final String title;
  final String subtitle;

  const _OnboardingPageData({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}

// ---------------------------------------------------------------------------
// Onboarding Screen
// ---------------------------------------------------------------------------
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // ── Page state ──────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── Sign-in overlay animations ──────────────────────────────────────────
  late AnimationController _signInController;
  late Animation<Offset> _signInSlideAnimation;
  bool _showSignIn = false;

  // ── Sign-in form state ──────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // ── Constants ───────────────────────────────────────────────────────────
  static const _primaryColor = Color(0xFFFF5D2E);
  static const _inactiveDotColor = Color(0xFFD9D9D9);
  static const _subtitleColor = Color(0xFF4B4B4B);

  // ── Onboarding content ──────────────────────────────────────────────────
  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      image: 'assets/Onboarding/1.png',
      title: "Your vehicle's\nbest friend",
      subtitle: 'We handle the maintenance,\nyou enjoy the ride.',
    ),
    _OnboardingPageData(
      image: 'assets/Onboarding/2.png',
      title: 'Effortless booking',
      subtitle:
          'Booking the most trusted mechanics has\nnever been smoother.',
    ),
    _OnboardingPageData(
      image: 'assets/Onboarding/3.png',
      title: 'Never miss a\nservice',
      subtitle: 'Receive alerts when your vehicle needs\nattention.',
    ),
    _OnboardingPageData(
      image: 'assets/Onboarding/4.png',
      title: 'Track your service\nhistory',
      subtitle:
          "Stay on top of your vehicle's health with a\nlog of every oil change, tire rotation, and\ninspection.",
    ),
  ];

  // ======================================================================
  // Lifecycle
  // ======================================================================

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    _signInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _signInSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _signInController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _signInController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ======================================================================
  // Navigation helpers
  // ======================================================================

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _showSignInOverlay();
    }
  }

  void _showSignInOverlay() {
    setState(() => _showSignIn = true);
    _signInController.forward();
  }

  void _hideSignInOverlay() {
    _signInController.reverse().then((_) {
      if (mounted) setState(() => _showSignIn = false);
    });
  }

  // ======================================================================
  // Sign-in handlers (mirrored from signin_screen.dart)
  // ======================================================================

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
        final response = await _supabaseService.signInWithEmail(
          email: email,
          password: password,
        );

        if (response.user != null && mounted) {
          _showSnackBar('Welcome back!', isError: false);

          final profile =
              await _supabaseService.getUserProfile(response.user!.id);
          if (!mounted) return;

          final role = profile != null
              ? profile['role']?.toString().toUpperCase()
              : 'CUSTOMER';

          if (role == 'MECHANIC') {
            context.go('/worker');
          } else if (role == 'ADMIN') {
            context.go('/admin');
          } else {
            context.go('/home');
          }
        } else if (mounted) {
          _showSnackBar('Login failed. Please check your credentials.');
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Invalid email or password. Please try again.';
          final errorStr = e.toString();
          if (errorStr.contains('Invalid login credentials')) {
            errorMessage = 'Invalid email or password.';
          } else if (errorStr.contains('Email not confirmed')) {
            errorMessage = 'Please verify your email address first.';
          } else if (errorStr.contains('Network') ||
              errorStr.contains('SocketException') ||
              errorStr.contains('Failed host lookup') ||
              errorStr.contains('ClientException') ||
              errorStr.contains('AuthRetryableFetchException')) {
            errorMessage =
                'Unable to connect to the server. Please check your internet connection and try again.';
          }
          _showSnackBar(errorMessage);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await _supabaseService.signInWithGoogle();
      if (success && mounted) {
        _showSnackBar('Signed in with Google!', isError: false);
        final user = _supabaseService.currentUser;
        if (user != null) {
          final profile = await _supabaseService.getUserProfile(user.id);
          if (!mounted) return;
          final role = profile != null
              ? profile['role']?.toString().toUpperCase()
              : 'CUSTOMER';
          if (role == 'MECHANIC') {
            context.go('/worker');
          } else if (role == 'ADMIN') {
            context.go('/admin');
          } else {
            context.go('/home');
          }
        } else {
          context.go('/home');
        }
      } else if (mounted) {
        _showSnackBar('Google sign-in cancelled or failed.');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Failed to sign in with Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookSignIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await _supabaseService.signInWithFacebook();
      if (success && mounted) {
        _showSnackBar('Signed in with Facebook!', isError: false);
        final user = _supabaseService.currentUser;
        if (user != null) {
          final profile = await _supabaseService.getUserProfile(user.id);
          if (!mounted) return;
          final role = profile != null
              ? profile['role']?.toString().toUpperCase()
              : 'CUSTOMER';
          if (role == 'MECHANIC') {
            context.go('/worker');
          } else if (role == 'ADMIN') {
            context.go('/admin');
          } else {
            context.go('/home');
          }
        } else {
          context.go('/home');
        }
      } else if (mounted) {
        _showSnackBar('Facebook sign-in cancelled or failed.');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Failed to sign in with Facebook.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        _showSnackBar('Password reset email sent! Check your inbox.',
            isError: false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Failed to send password reset email.');
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

  // ======================================================================
  // Build
  // ======================================================================

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Onboarding content ────────────────────────────────────────
          Column(
            children: [
              SizedBox(height: topPadding + 16),

              // Logo
              SvgPicture.asset('assets/Servio_Logo.svg', height: 70),

              const SizedBox(height: 8),

              // Swipeable page area (illustration + text)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildOnboardingPage(_pages[index]);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Page indicator dots
              _buildPageIndicator(),

              const SizedBox(height: 32),

              // Next / Continue button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildPrimaryButton(
                  label: _currentPage == _pages.length - 1
                      ? 'Continue'
                      : 'Next',
                  onTap: _onNextPressed,
                ),
              ),

              SizedBox(height: bottomPadding + 16),
            ],
          ),

          // ── Sign-in overlay ───────────────────────────────────────────
          if (_showSignIn) ...[
            // Dim background
            AnimatedBuilder(
              animation: _signInController,
              builder: (context, child) {
                return GestureDetector(
                  onTap: _hideSignInOverlay,
                  child: Container(
                    color: Colors.black
                        .withValues(alpha: _signInController.value * 0.45),
                  ),
                );
              },
            ),
            // Sliding sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _signInSlideAnimation,
                child: _buildSignInSheet(bottomPadding),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ======================================================================
  // Onboarding page content (inside PageView)
  // ======================================================================

  Widget _buildOnboardingPage(_OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Illustration
          SizedBox(
            width: 310,
            height: 252,
            child: Image.asset(
              page.image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.car_repair,
                    size: 80, color: _primaryColor),
              ),
            ),
          ),

          const Spacer(flex: 3),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 20),

          // Subtitle
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.instrumentSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _subtitleColor,
              height: 22 / 16,
            ),
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }

  // ======================================================================
  // Page indicator dots
  // ======================================================================

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
          width: isActive ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _primaryColor : _inactiveDotColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ======================================================================
  // Primary button (Next / Continue)
  // ======================================================================

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isLoading
              ? _primaryColor.withValues(alpha: 0.6)
              : _primaryColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isLoading ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        label,
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
    );
  }

  // ======================================================================
  // Sign-in bottom sheet
  // ======================================================================

  Widget _buildSignInSheet(double bottomPadding) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Grabber ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFCFCF),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),

            // ── Close button ─────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 4),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Material(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _hideSignInOverlay,
                      child: const Center(
                        child:
                            Icon(Icons.close, size: 24, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Form content ─────────────────────────────────────────────
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
                      'Welcome Back to Servio',
                      style: GoogleFonts.instrumentSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
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

                    // Email
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

                    // Password
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

                    // Log In button
                    _buildPrimaryButton(
                      label: 'Log In',
                      onTap: _handleSignIn,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Forgot password
                    Center(
                      child: GestureDetector(
                        onTap: _handleForgotPassword,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.instrumentSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black.withValues(alpha: 0.7),
                              decoration: TextDecoration.underline,
                              height: 22 / 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Sign up prompt
                    Center(
                      child: GestureDetector(
                        onTap: () => context.go('/signup'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            "Don't have an account? Sign Up",
                            style: GoogleFonts.instrumentSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withValues(alpha: 0.7),
                              height: 22 / 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Divider with "or"
                    _buildOrDivider(),
                    const SizedBox(height: 16),

                    // Google
                    _buildSocialLoginButton(
                      label: 'Log In with Google',
                      icon: Image.asset(
                        'assets/icons/google.png',
                        width: 24,
                        height: 24,
                      ),
                      onTap: _handleGoogleSignIn,
                    ),
                    const SizedBox(height: 16),

                    // Facebook
                    _buildSocialLoginButton(
                      label: 'Log In with Facebook',
                      icon: Image.asset(
                        'assets/icons/facebook.png',
                        width: 24,
                        height: 24,
                      ),
                      onTap: _handleFacebookSignIn,
                    ),

                    SizedBox(height: bottomPadding + 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================================
  // Input field
  // ======================================================================

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
          border:
              Border.all(color: Colors.black.withValues(alpha: 0.1)),
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
                      color: Colors.black.withValues(alpha: 0.5),
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
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: 20,
                    color: Colors.black.withValues(alpha: 0.5),
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

  // ======================================================================
  // Social login button
  // ======================================================================

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

  // ======================================================================
  // "or" divider
  // ======================================================================

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'or',
            style: GoogleFonts.instrumentSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}
