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
          'Please pass your environment variables when running the app:\n'
          '  - Flutter CLI: flutter run --dart-define-from-file=../../.env\n'
          '  - Android Studio: Select "Customer App" from the Run Configurations dropdown\n'
          '  - VS Code: Run using the "Customer App" launch configuration\n'
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
