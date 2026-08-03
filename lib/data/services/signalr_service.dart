import 'dart:async';

import 'package:atlas_flutter_app/core/logging/app_logger.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'package:atlas_flutter_app/core/config/app_config.dart';
import 'package:atlas_flutter_app/data/services/token_service.dart';

class SignalRService {
  final TokenService _tokenService;
  final _log = AppLog('Realtime');

  HubConnection? _hubConnection;
  bool _isConnected = false;

  // ─── Event Streams ──────────────────────────────────────────

  final _syncRequiredController = StreamController<void>.broadcast();
  final _achievementUnlockedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _levelUpController = StreamController<Map<String, dynamic>>.broadcast();
  final _xpGainedController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<void> get onSyncRequired => _syncRequiredController.stream;
  Stream<Map<String, dynamic>> get onAchievementUnlocked =>
      _achievementUnlockedController.stream;
  Stream<Map<String, dynamic>> get onLevelUp => _levelUpController.stream;
  Stream<Map<String, dynamic>> get onXpGained => _xpGainedController.stream;

  bool get isConnected => _isConnected;

  SignalRService(this._tokenService);

  // ─── Connection Management ──────────────────────────────────

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final token = await _tokenService.getAccessToken();
      if (token == null || token.isEmpty) {
        _log.w('SignalR: No access token available, skipping connection');
        return;
      }

      final hubUrl = '${AppConfig.baseUrl}/hubs/sync';

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                final t = await _tokenService.getAccessToken();
                return t ?? '';
              },
            ),
          )
          .withAutomaticReconnect()
          .build();

      _hubConnection!.onclose(({error}) {
        _isConnected = false;
        _log.i('SignalR: Connection closed${error != null ? ' ($error)' : ''}');
      });

      _hubConnection!.onreconnecting(({error}) {
        _isConnected = false;
        _log.i(
            'SignalR: Reconnecting${error != null ? ' ($error)' : ''}');
      });

      _hubConnection!.onreconnected(({connectionId}) {
        _isConnected = true;
        _log.i('SignalR: Reconnected (id: $connectionId)');
      });

      // Register event handlers
      _hubConnection!.on('SyncRequired', (arguments) {
        _log.d('SignalR: SyncRequired event received');
        _syncRequiredController.add(null);
      });

      _hubConnection!.on('AchievementUnlocked', (arguments) {
        _log.d('SignalR: AchievementUnlocked event received');
        if (arguments != null && arguments.isNotEmpty) {
          _achievementUnlockedController
              .add(arguments.first as Map<String, dynamic>);
        }
      });

      _hubConnection!.on('LevelUp', (arguments) {
        _log.d('SignalR: LevelUp event received');
        if (arguments != null && arguments.isNotEmpty) {
          _levelUpController.add(arguments.first as Map<String, dynamic>);
        }
      });

      _hubConnection!.on('XpGained', (arguments) {
        _log.d('SignalR: XpGained event received');
        if (arguments != null && arguments.isNotEmpty) {
          _xpGainedController.add(arguments.first as Map<String, dynamic>);
        }
      });

      await _hubConnection!.start();
      _isConnected = true;
      _log.i('SignalR: Connected to $hubUrl');
    } catch (e) {
      _isConnected = false;
      _log.e('SignalR: Failed to connect', error: e);
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      try {
        await _hubConnection!.stop();
      } catch (e) {
        _log.e('SignalR: Error during disconnect', error: e);
      }
      _isConnected = false;
      _log.i('SignalR: Disconnected');
    }
  }

  Future<void> reconnect() async {
    await disconnect();
    await connect();
  }

  void dispose() {
    disconnect();
    _syncRequiredController.close();
    _achievementUnlockedController.close();
    _levelUpController.close();
    _xpGainedController.close();
  }
}
