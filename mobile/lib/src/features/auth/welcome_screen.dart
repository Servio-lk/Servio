import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.car_repair, size: 80, color: Color(0xFFFF5D2E)),
            const SizedBox(height: 20),
            Text(
              'Welcome to Servio',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            FilledButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Sign Up'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.go('/signin'),
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Continue as Guest'),
            ),
          ],
        ),
      ),
    );
  }
}
