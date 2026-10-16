import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:atlas_flutter_app/core/logging/app_logger.dart';

import 'package:atlas_flutter_app/core/config/app_config.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/core/errors/error_handler.dart';
import 'package:atlas_flutter_app/data/services/token_service.dart';

final _log = AppLog('Api');

class ApiService {
  final TokenService _tokenService;
  late final Dio _dio;
  late final Dio _refreshDio;

  /// The in-flight token refresh, shared by every request that hits a 401
  /// while it runs. Each of those requests then retries *itself* with the new
  /// token, so no request is ever answered with another request's response.
  Future<String>? _refreshFuture;

  /// Marks a request that has already been retried after a refresh, so a
  /// second 401 is surfaced instead of triggering another refresh (or waiting
  /// on the refresh it is itself part of).
  static const _retriedKey = 'atlas_auth_retried';

  /// Optional callback invoked when an unrecoverable 401 occurs
  /// (e.g., refresh token expired). The app can use this to force logout.
  VoidCallback? onUnauthorized;

  /// [dio] and [refreshDio] are injectable for tests (e.g. with a fake
  /// `HttpClientAdapter`); production code uses the defaults.
  ApiService(this._tokenService, {Dio? dio, Dio? refreshDio}) {
    _dio = dio ?? Dio(_baseOptions());

    // Separate Dio instance for token refresh to avoid interceptor recursion
    _refreshDio = refreshDio ?? Dio(_baseOptions());

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  static BaseOptions _baseOptions() => BaseOptions(
        baseUrl: '${AppConfig.baseUrl}${AppConfig.apiPrefix}',
        connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

  // ─── Interceptors ───────────────────────────────────────────────

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenService.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    _log.d('[API] ${options.method} ${options.path}');
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    _log.w('[API] Error ${error.response?.statusCode} on ${error.requestOptions.method} ${error.requestOptions.path}: ${error.response?.data}');

    final options = error.requestOptions;

    // Only attempt refresh on 401 responses, and only once per request.
    if (error.response?.statusCode != 401 ||
        options.extra[_retriedKey] == true) {
      return handler.next(error);
    }

    final String newAccessToken;
    try {
      // If the token was already rotated after this request was sent (it lost
      // a race with a refresh that has since finished), retry with the
      // current token instead of refreshing again.
      final current = await _tokenService.getAccessToken();
      final sentWith = options.headers['Authorization'];
      if (_refreshFuture == null &&
          current != null &&
          current.isNotEmpty &&
          sentWith != null &&
          sentWith != 'Bearer $current') {
        newAccessToken = current;
      } else {
        newAccessToken = await (_refreshFuture ??=
            _refreshTokens().whenComplete(() => _refreshFuture = null));
      }
    } catch (_) {
      return handler.next(error);
    }

    // Retry this request with its own options and the new token.
    options.headers['Authorization'] = 'Bearer $newAccessToken';
    options.extra[_retriedKey] = true;
    try {
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    } catch (_) {
      return handler.next(error);
    }
  }

  /// Exchange the refresh token for a new pair and persist it. Returns the new
  /// access token. Clears the session (and fires [onUnauthorized]) when the
  /// server rejects the refresh or no refresh token exists; transient network
  /// failures keep the tokens so the user can retry once back online.
  Future<String> _refreshTokens() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const AuthException('No refresh token available');
      }

      final refreshResponse = await _refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccessToken = refreshResponse.data['access_token'] as String;
      final newRefreshToken = refreshResponse.data['refresh_token'] as String;

      await _tokenService.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return newAccessToken;
    } on DioException catch (refreshError) {
      // Only force logout if the server explicitly rejected the refresh
      // (e.g., 401/403). For network errors (offline, timeout), keep
      // tokens intact so the user can retry when connectivity returns.
      if (refreshError.type == DioExceptionType.badResponse) {
        await _tokenService.deleteTokens();
        onUnauthorized?.call();
      }
      rethrow;
    } catch (_) {
      // Unknown errors (not network-related) — force logout as a safety net
      await _tokenService.deleteTokens();
      onUnauthorized?.call();
      rethrow;
    }
  }

  // ─── Public HTTP Methods ────────────────────────────────────────

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// POST and read the response body as it arrives (server-sent events).
  /// Non-2xx responses still throw [AppException] with the status code.
  Future<Response<ResponseBody>> postStream(
    String path, {
    dynamic data,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<ResponseBody>(
        path,
        data: data,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          // Premium replies can take a while to start and keep arriving.
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }
}
