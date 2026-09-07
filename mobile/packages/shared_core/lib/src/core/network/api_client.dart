import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/supabase_service.dart';
import 'api_exceptions.dart';
import 'api_response.dart';

typedef TokenProvider = FutureOr<String?> Function();

class ApiClient {
  final http.Client _httpClient;
  final String _baseUrl;
  final TokenProvider? _tokenProvider;
  final Duration timeout;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    TokenProvider? tokenProvider,
    this.timeout = const Duration(seconds: 15),
  })  : _httpClient = client ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl ?? ApiConfig.apiBaseUrl),
        _tokenProvider = tokenProvider;

  static String _normalizeBaseUrl(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  String get baseUrl => _baseUrl;

  Future<String?> _resolveToken(String? explicitToken) async {
    if (explicitToken != null) return explicitToken;
    final provider = _tokenProvider;
    if (provider != null) {
      return await provider();
    }
    try {
      return SupabaseService().currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$_baseUrl$cleanPath';

    final uri = Uri.parse(fullUrl);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final queryMap = <String, dynamic>{
      ...uri.queryParameters,
      ...queryParameters.map((k, v) => MapEntry(k, v?.toString())),
    }..removeWhere((k, v) => v == null);

    return uri.replace(queryParameters: queryMap);
  }

  Future<Map<String, String>> _buildHeaders({
    Map<String, String>? customHeaders,
    String? token,
    bool hasBody = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (hasBody) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }

    final authToken = await _resolveToken(token);
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }

    return headers;
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic data)? fromJson,
    String? token,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requestHeaders = await _buildHeaders(
      customHeaders: headers,
      token: token,
      hasBody: false,
    );

    return _sendRequest<T>(
      () => _httpClient.get(uri, headers: requestHeaders).timeout(timeout),
      uri: uri,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic data)? fromJson,
    String? token,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requestHeaders = await _buildHeaders(
      customHeaders: headers,
      token: token,
      hasBody: body != null,
    );
    final encodedBody = body != null ? jsonEncode(body) : null;

    return _sendRequest<T>(
      () => _httpClient
          .post(uri, headers: requestHeaders, body: encodedBody)
          .timeout(timeout),
      uri: uri,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic data)? fromJson,
    String? token,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requestHeaders = await _buildHeaders(
      customHeaders: headers,
      token: token,
      hasBody: body != null,
    );
    final encodedBody = body != null ? jsonEncode(body) : null;

    return _sendRequest<T>(
      () => _httpClient
          .put(uri, headers: requestHeaders, body: encodedBody)
          .timeout(timeout),
      uri: uri,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic data)? fromJson,
    String? token,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requestHeaders = await _buildHeaders(
      customHeaders: headers,
      token: token,
      hasBody: body != null,
    );
    final encodedBody = body != null ? jsonEncode(body) : null;

    return _sendRequest<T>(
      () => _httpClient
          .patch(uri, headers: requestHeaders, body: encodedBody)
          .timeout(timeout),
      uri: uri,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic data)? fromJson,
    String? token,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final requestHeaders = await _buildHeaders(
      customHeaders: headers,
      token: token,
      hasBody: false,
    );

    return _sendRequest<T>(
      () => _httpClient.delete(uri, headers: requestHeaders).timeout(timeout),
      uri: uri,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> _sendRequest<T>(
    Future<http.Response> Function() requestFn, {
    required Uri uri,
    T Function(dynamic data)? fromJson,
  }) async {
    try {
      final response = await requestFn();
      return _handleResponse<T>(response, uri: uri, fromJson: fromJson);
    } on SocketException catch (e) {
      throw NetworkException(
        'Failed to connect to backend server at ${uri.host}:${uri.port}: ${e.message}',
      );
    } on TimeoutException {
      throw const NetworkException('Request timed out. Please try again.');
    } on http.ClientException catch (e) {
      throw NetworkException('HTTP client error: ${e.message}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error communicating with API: $e');
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response, {
    required Uri uri,
    T Function(dynamic data)? fromJson,
  }) {
    final statusCode = response.statusCode;
    final bodyString = response.body.trim();

    dynamic decodedJson;
    if (bodyString.isNotEmpty) {
      try {
        decodedJson = jsonDecode(bodyString);
      } catch (_) {
        decodedJson = null;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      if (decodedJson is Map<String, dynamic>) {
        if (decodedJson.containsKey('success') || decodedJson.containsKey('data')) {
          return ApiResponse<T>.fromJson(decodedJson, fromJson);
        }
        final parsedData = fromJson != null ? fromJson(decodedJson) : decodedJson as T;
        return ApiResponse<T>(
          success: true,
          data: parsedData,
          path: uri.path,
        );
      } else if (decodedJson is List) {
        final parsedData = fromJson != null ? fromJson(decodedJson) : decodedJson as T;
        return ApiResponse<T>(
          success: true,
          data: parsedData,
          path: uri.path,
        );
      } else {
        final parsedData = fromJson != null ? fromJson(decodedJson) : (decodedJson as T?);
        return ApiResponse<T>(
          success: true,
          data: parsedData,
          path: uri.path,
        );
      }
    }

    // Error response handling
    String message = 'API request failed with status code $statusCode';
    String? errorDetail;
    String? path = uri.path;
    String? traceId;
    Map<String, dynamic>? validationErrors;

    if (decodedJson is Map<String, dynamic>) {
      message = (decodedJson['message'] ?? decodedJson['error'] ?? message).toString();
      errorDetail = decodedJson['error']?.toString();
      path = decodedJson['path']?.toString() ?? path;
      traceId = decodedJson['traceId']?.toString();
      if (decodedJson['validationErrors'] is Map<String, dynamic>) {
        validationErrors = decodedJson['validationErrors'] as Map<String, dynamic>;
      }
    }

    switch (statusCode) {
      case 400:
        throw ValidationException(
          message,
          statusCode: 400,
          validationErrors: validationErrors,
          data: decodedJson,
          error: errorDetail,
          path: path,
          traceId: traceId,
        );
      case 401:
        throw UnauthorizedException(
          message,
          401,
          decodedJson,
          errorDetail,
          path,
          traceId,
        );
      case 403:
        throw ForbiddenException(
          message,
          403,
          decodedJson,
          errorDetail,
          path,
          traceId,
        );
      case 404:
        throw ResourceNotFoundException(
          message,
          404,
          decodedJson,
          errorDetail,
          path,
          traceId,
        );
      case 409:
        throw ConflictException(
          message,
          409,
          decodedJson,
          errorDetail,
          path,
          traceId,
        );
      case 429:
        final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
        throw RateLimitExceededException(
          message,
          429,
          retryAfter,
          decodedJson,
          errorDetail,
          path,
          traceId,
        );
      default:
        if (statusCode >= 500) {
          throw ServerException(
            message,
            statusCode,
            decodedJson,
            errorDetail,
            path,
            traceId,
          );
        }
        throw ApiException(
          message,
          statusCode: statusCode,
          data: decodedJson,
          error: errorDetail,
          path: path,
          traceId: traceId,
        );
    }
  }

  void close() {
    _httpClient.close();
  }
}
