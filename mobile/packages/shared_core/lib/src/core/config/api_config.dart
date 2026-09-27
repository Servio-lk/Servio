class ApiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'SERVIO_API_BASE_URL',
    defaultValue: 'https://api.servio.com/api',
  );

  static const List<String> fallbackApiBaseUrls = [
    'http://127.0.0.1:3001/api',
    'http://localhost:3001/api',
  ];
}
