class PlaceServiceException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;
  final StackTrace? stackTrace;

  const PlaceServiceException(
    this.message, {
    this.code,
    this.originalException,
    this.stackTrace,
  });

  factory PlaceServiceException.networkError([String? message]) {
    return PlaceServiceException(
      message ?? 'Network error occurred while fetching place data',
      code: 'NETWORK_ERROR',
    );
  }

  factory PlaceServiceException.apiError(String message, [String? code]) {
    return PlaceServiceException(
      message,
      code: code ?? 'API_ERROR',
    );
  }

  factory PlaceServiceException.parseError([String? message]) {
    return PlaceServiceException(
      message ?? 'Failed to parse place data',
      code: 'PARSE_ERROR',
    );
  }

  factory PlaceServiceException.notFound([String? message]) {
    return PlaceServiceException(
      message ?? 'Place not found',
      code: 'NOT_FOUND',
    );
  }

  factory PlaceServiceException.unauthorized([String? message]) {
    return PlaceServiceException(
      message ?? 'Unauthorized access to place service',
      code: 'UNAUTHORIZED',
    );
  }

  factory PlaceServiceException.quotaExceeded([String? message]) {
    return PlaceServiceException(
      message ?? 'API quota exceeded',
      code: 'QUOTA_EXCEEDED',
    );
  }

  @override
  String toString() {
    if (code != null) {
      return 'PlaceServiceException($code): $message';
    }
    return 'PlaceServiceException: $message';
  }
}