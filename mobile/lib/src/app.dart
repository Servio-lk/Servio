import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart';

class ServioApp extends ConsumerWidget {
  const ServioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Servio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5D2E), // Servio Orange
          primary: const Color(0xFFFF5D2E),
          surface: const Color(0xFFFFF7F5),
        ),
        // Set Instrument Sans as the default font for all text
        textTheme: GoogleFonts.instrumentSansTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFBFBFB),
        // Override specific text styles to use Instrument Sans
        fontFamily: GoogleFonts.instrumentSans().fontFamily,
      ),
      routerConfig: router,
    );
  }
}
