import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'package:shared_core/shared_core.dart';
import 'features/worker/worker_dashboard_screen.dart';
import 'features/chats/worker_chat_screen.dart';
import 'features/auth/mechanic_signup_email_screen.dart';
import 'features/auth/mechanic_signup_verify_screen.dart';
import 'features/auth/mechanic_signup_password_screen.dart';
import 'features/auth/mechanic_signup_otp_screen.dart';
import 'features/profile/mechanic_profile_wizard_screen.dart';
import 'features/jobs/qr_scan_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    onException: (context, state, router) {
      final uri = state.uri;
      final uriStr = uri.toString();
      if (uriStr.contains('login-callback') ||
          uri.scheme == 'io.supabase.servio' ||
          uri.scheme == 'servio') {
        return;
      }
      debugPrint('GoRouter unhandled exception for ${state.uri}: ${state.error}');
      router.go('/splash');
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(unauthenticatedRoute: '/signin'),
      ),
      GoRoute(
        path: '/login-callback',
        builder: (context, state) => const SplashScreen(unauthenticatedRoute: '/signin'),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(allowedRole: 'MECHANIC'),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const MechanicSignupEmailScreen(),
      ),
      GoRoute(
        path: '/signup/verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return MechanicSignupVerifyScreen(mechanic: extra['mechanic']);
        },
      ),
      GoRoute(
        path: '/signup/password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return MechanicSignupPasswordScreen(mechanic: extra['mechanic']);
        },
      ),
      GoRoute(
        path: '/signup/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return MechanicSignupOtpScreen(extras: extra);
        },
      ),
      GoRoute(
        path: '/worker',
        builder: (context, state) => const WorkerDashboardScreen(),
      ),
      GoRoute(
        path: '/profile/complete',
        builder: (context, state) => const MechanicProfileWizardScreen(),
      ),
      GoRoute(
        path: '/worker/chat/:appointmentId',
        builder: (context, state) => WorkerChatScreen(
          appointmentId: int.parse(state.pathParameters['appointmentId']!),
        ),
      ),
      GoRoute(
        path: '/jobs/scan-qr',
        builder: (context, state) => const QrScanScreen(),
      ),
    ],
  );
});
