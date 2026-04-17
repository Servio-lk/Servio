import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'features/auth/splash_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/auth/signin_screen.dart';
import 'features/auth/signup_step1_screen.dart';
import 'features/auth/signup_otp_screen.dart';
import 'features/auth/signup_step2_screen.dart';
import 'features/auth/signup_step3_screen.dart';
import 'shared/main_navigation_screen.dart';
import 'features/worker/worker_dashboard_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';

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
      GoRoute(
        path: '/worker',
        builder: (context, state) => const WorkerDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});
