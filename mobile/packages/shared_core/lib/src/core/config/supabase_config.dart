class SupabaseConfig {
  static const String _defaultUrl = 'https://szgvnurzdglflmdabjol.supabase.co';
  static const String _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6Z3ZudXJ6ZGdsZmxtZGFiam9sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4OTc3NTgsImV4cCI6MjA4NDQ3Mzc1OH0.MeQsJIGJ-Fy9GLrcHg3M1rM-eEIpmKKsRsrVYPI6U6E';

  static const String _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl => _envUrl.isNotEmpty ? _envUrl : _defaultUrl;
  static String get supabaseAnonKey =>
      _envAnonKey.isNotEmpty ? _envAnonKey : _defaultAnonKey;

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
