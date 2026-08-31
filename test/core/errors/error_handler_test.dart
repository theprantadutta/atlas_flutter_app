import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/core/errors/error_handler.dart';
import 'package:atlas_flutter_app/core/errors/error_messages.dart';

/// The backend writes user-facing sentences and sends them as `{"error": ...}`.
/// These check the ones that must survive the trip, and the ones that must not
/// be believed.
void main() {
  DioException responseError(int status, {String? serverMessage}) {
    final request = RequestOptions(path: '/billing/verify');
    return DioException(
      requestOptions: request,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: request,
        statusCode: status,
        data: serverMessage == null ? null : {'error': serverMessage},
      ),
    );
  }

  group('handleDioError', () {
    test('a 403 keeps the reason the server gave', () {
      // Billing returns 403 when a purchase belongs to another account. That
      // sentence tells the user what to do; "Access denied." does not. The
      // message is dropped if either end stops passing it through, so this
      // guards both the Dart mapping and the API returning a body at all.
      const reason =
          'This purchase is already linked to a different Atlas account. '
          'Sign in with that account to use it.';

      final result = ErrorHandler.handleDioError(
        responseError(403, serverMessage: reason),
      );

      expect(result, isA<AuthException>());
      expect(result.message, reason);
      expect(result.statusCode, 403);
    });

    test('a 403 with no body still says something', () {
      final result = ErrorHandler.handleDioError(responseError(403));
      expect(result.message, 'Access denied.');
    });

    test('the reason survives all the way to the text a user sees', () {
      const reason = 'This purchase is already linked to a different account.';

      final shown = AppErrors.message(
        ErrorHandler.handleDioError(responseError(403, serverMessage: reason)),
      );

      expect(shown, reason);
    });

    test('a 402 keeps its message too', () {
      // 402 is the store rejecting a purchase, and the client treats it as
      // terminal, so the wording is the only thing the user gets.
      const reason = 'Purchase could not be validated with the store.';

      final result = ErrorHandler.handleDioError(
        responseError(402, serverMessage: reason),
      );

      expect(result.message, reason);
    });

    test('a 404 does not repeat a server message', () {
      // Nothing useful to say, and the raw one tends to leak internals.
      final result = ErrorHandler.handleDioError(
        responseError(404, serverMessage: 'Purchase entity not found in ledger'),
      );

      expect(result.message, 'Resource not found.');
    });

    test('a timeout is a network problem, not a rejection', () {
      final result = ErrorHandler.handleDioError(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.receiveTimeout,
      ));

      expect(result, isA<NetworkException>());
    });

    test('a transform timeout is not reported as a connection timeout', () {
      // It fires when decoding a response that already arrived stalls. Telling
      // the user their connection timed out would send them to check their wifi.
      final result = ErrorHandler.handleDioError(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.transformTimeout,
      ));

      expect(result, isNot(isA<NetworkException>()));
    });
  });
}
