class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;
  final String? path;
  final String? timestamp;
  final String? traceId;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.path,
    this.timestamp,
    this.traceId,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic json)? fromJsonT,
  ]) {
    final success = (json['success'] as bool?) ?? true;
    final rawData = json['data'];
    T? data;

    if (rawData != null) {
      if (fromJsonT != null) {
        data = fromJsonT(rawData);
      } else if (rawData is T) {
        data = rawData;
      }
    }

    return ApiResponse<T>(
      success: success,
      message: json['message'] as String?,
      data: data,
      error: json['error'] as String?,
      path: json['path'] as String?,
      timestamp: json['timestamp'] as String?,
      traceId: json['traceId'] as String?,
    );
  }

  Map<String, dynamic> toJson([Object? Function(T value)? toJsonT]) {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null) 'data': toJsonT != null ? toJsonT(data as T) : data,
      if (error != null) 'error': error,
      if (path != null) 'path': path,
      if (timestamp != null) 'timestamp': timestamp,
      if (traceId != null) 'traceId': traceId,
    };
  }
}
