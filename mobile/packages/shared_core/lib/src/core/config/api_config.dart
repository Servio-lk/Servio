class ApiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'SERVIO_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
  );

  static const List<String> fallbackApiBaseUrls = [
    'http://127.0.0.1:8080/api',
    'http://localhost:8080/api',
  ];
}
