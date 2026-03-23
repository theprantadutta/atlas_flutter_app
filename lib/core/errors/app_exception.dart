class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => 'AppException: $message (statusCode: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.statusCode});

  @override
  String toString() => 'NetworkException: $message (statusCode: $statusCode)';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.statusCode});

  @override
  String toString() => 'AuthException: $message (statusCode: $statusCode)';
}

class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});

  @override
  String toString() => 'ServerException: $message (statusCode: $statusCode)';
}

class CacheException extends AppException {
  const CacheException(super.message, {super.statusCode});

  @override
  String toString() => 'CacheException: $message (statusCode: $statusCode)';
}
