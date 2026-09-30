import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const String _envUrl = String.fromEnvironment('SERVIO_API_BASE_URL');
  static String? _overrideUrl;

  static void setBaseUrl(String? url) {
    _overrideUrl = url;
  }

  static String get apiBaseUrl {
    if (_overrideUrl != null && _overrideUrl!.isNotEmpty) {
      return _overrideUrl!;
    }
    if (_envUrl.isNotEmpty) {
      return _envUrl;
    }
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          return 'http://10.0.2.2:3001/api';
        }
      } catch (_) {}
    }
    return 'http://localhost:3001/api';
  }

  static const List<String> fallbackApiBaseUrls = [
    'http://10.0.2.2:3001/api',
    'http://127.0.0.1:3001/api',
    'http://localhost:3001/api',
  ];
}
