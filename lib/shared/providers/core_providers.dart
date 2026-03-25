import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:atlas_flutter_app/data/database/atlas_database.dart';
import 'package:atlas_flutter_app/data/services/token_service.dart';
import 'package:atlas_flutter_app/data/services/api_service.dart';
import 'package:atlas_flutter_app/data/services/auth_service.dart';
import 'package:atlas_flutter_app/data/services/offline_manager.dart';
import 'package:atlas_flutter_app/data/services/signalr_service.dart';
import 'package:atlas_flutter_app/data/services/fcm_service.dart';
import 'package:atlas_flutter_app/data/services/local_notification_service.dart';
import 'package:atlas_flutter_app/data/repositories/repository_providers.dart';

final databaseProvider = Provider<AtlasDatabase>((ref) {
  return AtlasDatabase();
});

final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(ref.read(tokenServiceProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.read(apiServiceProvider),
    ref.read(tokenServiceProvider),
  );
});

// ─── SignalR Service ──────────────────────────────────────────

final signalRServiceProvider = Provider<SignalRService>((ref) {
  return SignalRService(ref.read(tokenServiceProvider));
});

// ─── FCM Service ────────────────────────────────────────────

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(
    ref.read(apiServiceProvider),
    ref.read(tokenServiceProvider),
  );
});

// ─── Local Notification Service ─────────────────────────────

final localNotificationServiceProvider =
    Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

// ─── Sync Stream Providers ───────────────────────────────────

/// Sync status stream (for UI consumption).
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.read(offlineManagerProvider).syncStatus;
});

/// Pending operations count stream.
final pendingOperationsCountProvider = StreamProvider<int>((ref) {
  return ref.read(syncDaoProvider).watchPendingCount();
});

/// Last sync time stream.
final lastSyncTimeProvider = StreamProvider<DateTime?>((ref) {
  return ref.read(offlineManagerProvider).lastSyncTimeStream;
});
