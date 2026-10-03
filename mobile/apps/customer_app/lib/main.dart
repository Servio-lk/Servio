import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/app.dart';
import 'package:shared_core/shared_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use bundled fonts instead of fetching from the network
  GoogleFonts.config.allowRuntimeFetching = true;

  // Validate environment variables before initializing external services
  SupabaseConfig.validate();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(),
    ),
  );

  // Initialize Push Notifications (handles FCM tokens & local banners defensively)
  await PushNotificationService.instance.initialize();

  runApp(const ProviderScope(child: ServioApp()));
}
