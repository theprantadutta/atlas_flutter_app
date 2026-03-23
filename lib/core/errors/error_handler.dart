import 'package:dio/dio.dart';

import 'app_exception.dart';

class ErrorHandler {
  static AppException handleDioError(DioException error) {
    String message = 'An unexpected error occurred';

    // Try to extract the error message from the backend response
    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      if (data.containsKey('error')) {
        message = data['error'] as String;
      }
    }

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
              message.isNotEmpty ? message : 'Unauthorized. Please log in.',
              statusCode: statusCode,
            );
          case 403:
            return AuthException(
              'Access denied.',
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

      case DioExceptionType.unknown:
        return AppException(message, statusCode: error.response?.statusCode);
    }
  }
}
