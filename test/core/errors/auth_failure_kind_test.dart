import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/core/errors/error_messages.dart';

void main() {
  test('a sign-in the person backed out of is "cancelled"', () {
    expect(AppErrors.authFailureKind(PlatformException(code: 'sign_in_canceled')), 'cancelled');
  });

  test('no connection is "network"', () {
    expect(AppErrors.authFailureKind(const SocketException('down')), 'network');
    expect(AppErrors.authFailureKind(TimeoutException('slow')), 'network');
  });

  test('a wrong password or taken email is "rejected"', () {
    expect(AppErrors.authFailureKind(const AuthException('Invalid credentials', statusCode: 401)),
        'rejected');
  });

  test('a server failure is "server"', () {
    expect(AppErrors.authFailureKind(const AppException('boom', statusCode: 503)), 'server');
  });

  test('anything else is "other", never the message itself', () {
    expect(AppErrors.authFailureKind(StateError('unexpected')), 'other');
  });
}
