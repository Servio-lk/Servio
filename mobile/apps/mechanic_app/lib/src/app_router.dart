import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import 'package:shared_core/shared_core.dart';
import 'features/worker/worker_dashboard_screen.dart';
import 'features/worker/worker_chat_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/worker',
        builder: (context, state) => const WorkerDashboardScreen(),
      ),
      GoRoute(
        path: '/worker/chat/:appointmentId',
        builder: (context, state) => WorkerChatScreen(
          appointmentId: int.parse(state.pathParameters['appointmentId']!),
        ),
      ),
    ],
  );
});
