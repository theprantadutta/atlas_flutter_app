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

/// The person is using Atlas without an account, and this needs one (Aurora,
/// purchases, sync). Raised before any request is sent. It travels the same
/// road as the premium gate, so whatever opened the paywall for a free user
/// now opens it for a guest, and the router turns that into sign-up.
class AccountRequiredException extends AppException {
  const AccountRequiredException()
      : super('Create a free account to use this.', statusCode: 401);

  @override
  String toString() => 'AccountRequiredException';
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
