import 'package:dio/dio.dart';

import 'app_exception.dart';

class ErrorHandler {
  static AppException handleDioError(DioException error) {
    // Whether the backend actually sent a sentence, kept separate from the
    // fallback. Folding the two together makes every `isNotEmpty ? x : default`
    // below unreachable, since the default is itself non-empty, and the caller
    // silently gets the generic text instead of the specific one.
    String? serverMessage;
    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      final value = data['error'];
      if (value is String && value.trim().isNotEmpty) {
        serverMessage = value.trim();
      }
    }

    final message = serverMessage ?? 'An unexpected error occurred';

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          'Connection timed out. Please try again.',
          statusCode: error.response?.statusCode,
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          'No internet connection. Please check your network.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 400:
            return ServerException(message, statusCode: statusCode);
          case 401:
            return AuthException(
              serverMessage ?? 'Unauthorized. Please log in.',
              statusCode: statusCode,
            );
          case 403:
            // Prefer the server's own sentence. A 403 is not always about auth:
            // billing uses it to say a purchase belongs to another account, and
            // "Access denied." would leave the user with no idea what to do.
            return AuthException(
              serverMessage ?? 'Access denied.',
              statusCode: statusCode,
            );
          case 404:
            return ServerException(
              'Resource not found.',
              statusCode: statusCode,
            );
          case 409:
            return ServerException(message, statusCode: statusCode);
          case 422:
            return ServerException(message, statusCode: statusCode);
          case 429:
            return ServerException(
              'Too many requests. Please try again later.',
              statusCode: statusCode,
            );
          case 500:
          case 502:
          case 503:
            return ServerException(
              'Server error. Please try again later.',
              statusCode: statusCode,
            );
          default:
            return ServerException(message, statusCode: statusCode);
        }

      case DioExceptionType.cancel:
        return const AppException('Request was cancelled.');

      case DioExceptionType.badCertificate:
        return const NetworkException('Invalid security certificate.');

      // Not a network condition: the response arrived but decoding it stalled.
      // Nothing the user can act on, so it reads the same as any other
      // unexpected failure.
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return AppException(message, statusCode: error.response?.statusCode);
    }
  }
}
