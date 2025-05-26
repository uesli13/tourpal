import 'base_exception.dart';

/// Base exception for all network-related errors.
class NetworkException extends TourPalException {
  const NetworkException(super.message, [super.code]);
}

/// Exception thrown when a network request fails due to connectivity issues.
class ConnectivityException extends NetworkException {
  const ConnectivityException(super.message, [super.code]);

  factory ConnectivityException.noInternet() {
    return const ConnectivityException(
      'No internet connection available',
      'no-internet',
    );
  }

  factory ConnectivityException.offline() {
    return const ConnectivityException(
      'App is in offline mode',
      'offline-mode',
    );
  }

  factory ConnectivityException.serverUnreachable() {
    return const ConnectivityException(
      'Server is unreachable',
      'server-unreachable',
    );
  }
}

/// Exception thrown when a network request times out.
class TimeoutException extends NetworkException {
  const TimeoutException(super.message, [super.code]);

  factory TimeoutException.requestTimeout() {
    return const TimeoutException(
      'Request timed out',
      'request-timeout',
    );
  }

  factory TimeoutException.slowConnection() {
    return const TimeoutException(
      'Connection is too slow',
      'slow-connection',
    );
  }
}

/// Exception thrown when server returns an error response.
class ServerException extends NetworkException {
  final int? statusCode;

  const ServerException(super.message, [super.code, this.statusCode]);

  factory ServerException.internalError() {
    return const ServerException(
      'Internal server error',
      'server-error',
      500,
    );
  }

  factory ServerException.badRequest() {
    return const ServerException(
      'Bad request',
      'bad-request',
      400,
    );
  }

  factory ServerException.unauthorized() {
    return const ServerException(
      'Unauthorized',
      'unauthorized',
      401,
    );
  }

  factory ServerException.forbidden() {
    return const ServerException(
      'Forbidden',
      'forbidden',
      403,
    );
  }

  factory ServerException.notFound() {
    return const ServerException(
      'Resource not found',
      'not-found',
      404,
    );
  }

  factory ServerException.fromStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return ServerException.badRequest();
      case 401:
        return ServerException.unauthorized();
      case 403:
        return ServerException.forbidden();
      case 404:
        return ServerException.notFound();
      case 500:
        return ServerException.internalError();
      default:
        return ServerException(
          'Server error with status code: $statusCode',
          'server-error-$statusCode',
          statusCode,
        );
    }
  }
}

/// Exception thrown when a response cannot be parsed.
class ParsingException extends NetworkException {
  const ParsingException(super.message, [super.code]);

  factory ParsingException.invalidFormat() {
    return const ParsingException(
      'Invalid response format',
      'invalid-format',
    );
  }

  factory ParsingException.missingField(String field) {
    return ParsingException(
      'Missing required field: $field',
      'missing-field',
    );
  }
}