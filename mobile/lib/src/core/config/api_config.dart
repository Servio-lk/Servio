class ApiConfig {
  // Override with --dart-define=API_BASE_URL=https://your-host/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001/api',
  );
}

