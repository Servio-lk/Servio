import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'package:shared_core/shared_core.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/auth/signup_step1_screen.dart';
import 'features/auth/signup_step2_screen.dart';
import 'features/auth/signup_step3_screen.dart';
import 'features/auth/signup_otp_screen.dart';
import 'shared/main_navigation_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      // ── Sign-up flow (4 steps) ──────────────────────────────────────
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return SignUpStep1Screen(extras: extras);
        },
      ),
      GoRoute(
        path: '/signup/otp',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return SignUpOtpScreen(extras: extras);
        },
      ),
      GoRoute(
        path: '/signup/vehicle',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return SignUpStep2Screen(extras: extras);
        },
      ),
      GoRoute(
        path: '/signup/mileage',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return SignUpStep3Screen(extras: extras);
        },
      ),
      // ── Main app ───────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
    ],
  );
});
