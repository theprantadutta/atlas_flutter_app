import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl => kReleaseMode
      ? dotenv.env['API_BASE_URL_PROD'] ?? 'https://atlas.pranta.dev'
      : dotenv.env['API_BASE_URL_DEV'] ?? 'http://10.0.2.2:8020';

  static String get apiPrefix => '/api/v1';
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  /// Demo mode drives the app entirely from local sample data (no backend).
  /// Used during the UI redesign; set to false once the backend is wired.
  static const bool demoMode = true;
}
