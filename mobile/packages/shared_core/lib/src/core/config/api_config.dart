class ApiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'SERVIO_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001/api',
  );

  static const List<String> fallbackApiBaseUrls = [
    'http://127.0.0.1:3001/api',
    'http://localhost:3001/api',
  ];
}
