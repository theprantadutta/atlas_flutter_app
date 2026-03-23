import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:atlas_flutter_app/core/config/app_config.dart';

import 'package:atlas_flutter_app/core/errors/app_exception.dart';
import 'package:atlas_flutter_app/core/errors/error_handler.dart';
import 'package:atlas_flutter_app/data/services/token_service.dart';

class ApiService {
  final TokenService _tokenService;
  late final Dio _dio;
  late final Dio _refreshDio;

  bool _isRefreshing = false;
  final List<Completer<Response>> _pendingRequests = [];

  /// Optional callback invoked when an unrecoverable 401 occurs
  /// (e.g., refresh token expired). The app can use this to force logout.
  VoidCallback? onUnauthorized;

  ApiService(this._tokenService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.baseUrl}${AppConfig.apiPrefix}',
        connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Separate Dio instance for token refresh to avoid interceptor recursion
    _refreshDio = Dio(
      BaseOptions(
        baseUrl: '${AppConfig.baseUrl}${AppConfig.apiPrefix}',
        connectTimeout: Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  // ─── Interceptors ───────────────────────────────────────────────

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await _tokenService.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // Only attempt refresh on 401 responses
    if (error.response?.statusCode != 401) {
      return handler.next(error);
    }

    // If already refreshing, queue this request and wait
    if (_isRefreshing) {
      final completer = Completer<Response>();
      _pendingRequests.add(completer);
      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (e) {
        return handler.next(error);
      }
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const AuthException('No refresh token available');
      }

      // Attempt to refresh using the separate Dio instance
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

      // Retry the original failed request
      final requestOptions = error.requestOptions;
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _dio.fetch(requestOptions);

      // Resolve all queued requests
      for (final completer in _pendingRequests) {
        completer.complete(retryResponse);
      }
      _pendingRequests.clear();

      return handler.resolve(retryResponse);
    } on DioException catch (_) {
      // Refresh failed — clear tokens and notify
      await _tokenService.deleteTokens();
      onUnauthorized?.call();

      // Reject all queued requests
      for (final completer in _pendingRequests) {
        completer.completeError(error);
      }
      _pendingRequests.clear();

      return handler.next(error);
    } catch (_) {
      await _tokenService.deleteTokens();
      onUnauthorized?.call();

      for (final completer in _pendingRequests) {
        completer.completeError(error);
      }
      _pendingRequests.clear();

      return handler.next(error);
    } finally {
      _isRefreshing = false;
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
