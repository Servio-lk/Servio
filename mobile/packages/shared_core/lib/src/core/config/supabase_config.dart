class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Validates that required Supabase credentials have been injected at compile time
  /// via `--dart-define` or `--dart-define-from-file`.
  ///
  /// Throws [StateError] with actionable instructions if variables are missing.
  static void validate() {
    assert(() {
      final List<String> missing = [];
      if (supabaseUrl.trim().isEmpty) missing.add('SUPABASE_URL');
      if (supabaseAnonKey.trim().isEmpty) missing.add('SUPABASE_ANON_KEY');
      if (missing.isNotEmpty) {
        throw StateError(
          'Missing required environment configuration: ${missing.join(', ')}.\n'
          '  - Flutter CLI (from app dir): flutter run --dart-define-from-file=../../../.env\n'
          '  - Flutter CLI (from root dir): flutter run --target mobile/apps/mechanic_app/lib/main.dart --dart-define-from-file=.env\n'
          '  - VS Code / Android Studio: Run using predefined launch configuration (passes root .env)\n'
          'Refer to your project .env or .env.example for required values.',
        );
      }
      final uri = Uri.tryParse(supabaseUrl);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        throw StateError(
          'Invalid SUPABASE_URL: "$supabaseUrl". '
          'It must be a valid URL with scheme and host (e.g. https://<project-ref>.supabase.co).',
        );
      }
      return true;
    }());
  }
}
