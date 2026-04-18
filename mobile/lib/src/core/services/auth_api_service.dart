import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AuthApiService {
  const AuthApiService();

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<void> requestSignupOtp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/auth/signup/request-otp'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    _throwIfError(response, defaultMessage: 'Failed to send verification code.');
  }

  Future<void> verifySignupOtp({
    required String email,
    required String otp,
  }) async {
    final response = await http.post(
      _uri('/auth/signup/verify-otp'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
      }),
    );

    _throwIfError(response, defaultMessage: 'Invalid verification code.');
  }

  Future<void> resendSignupOtp({required String email}) async {
    final response = await http.post(
      _uri('/auth/signup/resend-otp'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    _throwIfError(response, defaultMessage: 'Failed to resend verification code.');
  }

  void _throwIfError(http.Response response, {required String defaultMessage}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String message = defaultMessage;
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        message = (body['message'] as String?)?.trim().isNotEmpty == true
            ? body['message'] as String
            : defaultMessage;
      }
    } catch (_) {
      // Keep default message when body is not JSON.
    }

    throw Exception(message);
  }
}

