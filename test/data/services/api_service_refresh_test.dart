import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/data/services/token_service.dart';

/// In-memory token store; only the members ApiService touches are real.
class _FakeTokenService implements TokenService {
  _FakeTokenService({this.access, this.refresh});

  String? access;
  String? refresh;
  int deletes = 0;

  @override
  Future<String?> getAccessToken() async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> deleteTokens() async {
    deletes++;
    access = null;
    refresh = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Serves each request through [handler].
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late _FakeTokenService tokens;
  late int refreshCalls;
  late Map<String, int> hits;

  Dio apiDio() => Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = _FakeAdapter((o) async {
      hits[o.path] = (hits[o.path] ?? 0) + 1;
      // Only the rotated token is accepted.
      if (o.headers['Authorization'] != 'Bearer new-access') {
        return _json(401, {'error': 'expired'});
      }
      return _json(200, {'path': o.path, 'method': o.method});
    });

  setUp(() {
    tokens = _FakeTokenService(access: 'old-access', refresh: 'r1');
    refreshCalls = 0;
    hits = {};
  });

  test('concurrent 401s refresh once and each request gets its own response',
      () async {
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = _FakeAdapter((o) async {
        refreshCalls++;
        // Slow enough that every request below has hit its 401 first.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _json(200, {
          'access_token': 'new-access',
          'refresh_token': 'r2',
        });
      });
    final api = ApiService(tokens, dio: apiDio(), refreshDio: refreshDio);

    final results = await Future.wait([
      api.get('/tasks'),
      api.get('/habits'),
      api.post('/sync/pull', data: {'x': 1}),
    ]);

    expect(refreshCalls, 1);
    expect(results[0].data['path'], '/tasks');
    expect(results[1].data['path'], '/habits');
    expect(results[2].data['path'], '/sync/pull');
    expect(results[2].data['method'], 'POST');
    expect(tokens.access, 'new-access');
    expect(tokens.refresh, 'r2');
  });

  test('a rejected refresh fails every queued request and logs out', () async {
    var unauthorized = 0;
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = _FakeAdapter((o) async {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _json(401, {'error': 'revoked'});
      });
    final api = ApiService(tokens, dio: apiDio(), refreshDio: refreshDio)
      ..onUnauthorized = () => unauthorized++;

    Future<Object> outcome(String path) async {
      try {
        await api.get(path);
        return 'ok';
      } catch (e) {
        return e;
      }
    }

    final outcomes = await Future.wait([outcome('/a'), outcome('/b')]);

    expect(refreshCalls, 1);
    expect(outcomes, everyElement(isA<AppException>()));
    expect(unauthorized, 1);
    expect(tokens.deletes, 1);
  });

  test('a retried request that 401s again is not retried forever', () async {
    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = _FakeAdapter((o) async {
        refreshCalls++;
        return _json(200, {
          'access_token': 'still-wrong',
          'refresh_token': 'r2',
        });
      });
    final api = ApiService(tokens, dio: apiDio(), refreshDio: refreshDio);

    await expectLater(
      api.get('/a').timeout(const Duration(seconds: 2)),
      throwsA(isA<AppException>()),
    );
    expect(refreshCalls, 1);
    expect(hits['/a'], 2);
  });
}
