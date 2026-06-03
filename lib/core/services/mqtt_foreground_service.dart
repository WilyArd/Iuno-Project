import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mqtt_service.dart';

// ─────────────────────────────────────────────────────────────────
// Entry point callback — must be top-level (not inside any class)
// @pragma ensures it is kept in release/AOT builds
// ─────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void mqttForegroundServiceCallback() {
  FlutterForegroundTask.setTaskHandler(MqttForegroundTaskHandler());
}

/// Manages the MQTT connection inside the foreground service isolate.
/// The service keeps the socket alive when the app is minimized/screen off.
/// It is automatically destroyed when the user swipes the app from recents
/// (stopWithTask="true" in AndroidManifest).
class MqttForegroundTaskHandler extends TaskHandler {
  MqttService? _mqttService;
  bool _isConnected = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _connectMqtt();
  }

  /// Called every 30 seconds — used to verify connection is still alive
  /// and update the notification text with current status.
  @override
  void onRepeatEvent(DateTime timestamp) {
    final status = _isConnected ? 'Connected • Monitoring IoT' : 'Reconnecting…';
    FlutterForegroundTask.updateService(notificationText: status);

    // If connection dropped, attempt to reconnect
    if (!_isConnected && _mqttService != null) {
      _reconnect();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _mqttService?.disconnect();
    _mqttService = null;
    _isConnected = false;
  }

  @override
  void onReceiveData(Object data) {
    // Commands from the main isolate (UI)
    if (data is Map) {
      final action = data['action'] as String?;
      if (action == 'disconnect') {
        _mqttService?.disconnect();
        _isConnected = false;
        FlutterForegroundTask.updateService(notificationText: 'Disconnected');
      }
    }
  }

  // ─── Internal helpers ──────────────────────────────────────────

  Future<void> _connectMqtt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool secure = prefs.getBool('mqtt_use_tls') ?? false;
      String host = prefs.getString('mqtt_host') ?? '192.168.10.3';
      if (secure) {
        final tlsHost = prefs.getString('mqtt_tls_host') ?? '';
        if (tlsHost.isNotEmpty) host = tlsHost;
      }

      // Sanitize host string
      host = _sanitizeHost(host);

      final int port = prefs.getInt('mqtt_port') ?? 1883;
      final String username = prefs.getString('mqtt_username') ?? '';
      final String password = prefs.getString('mqtt_password') ?? '';

      _mqttService = MqttService();
      _mqttService!.setup(
        host,
        'iuno_bg_${DateTime.now().millisecondsSinceEpoch}',
        port: port,
        secure: secure,
      );

      final connected = await _mqttService!.connect(
        username: username.isNotEmpty ? username : null,
        password: password.isNotEmpty ? password : null,
      );

      _isConnected = connected;
      final status = connected ? 'Connected • Monitoring IoT' : 'Connection failed';
      FlutterForegroundTask.updateService(notificationText: status);

      // Notify UI about connection result
      FlutterForegroundTask.sendDataToMain({
        'event': 'connection_changed',
        'connected': connected,
      });
    } catch (e) {
      _isConnected = false;
      FlutterForegroundTask.updateService(notificationText: 'Error: $e');
    }
  }

  Future<void> _reconnect() async {
    _isConnected = false;
    _mqttService?.disconnect();
    await Future.delayed(const Duration(seconds: 3));
    await _connectMqtt();
  }

  String _sanitizeHost(String host) {
    host = host.trim();
    for (final prefix in ['mqtts://', 'mqtt://', 'ssl://', 'tcp://', 'wss://', 'ws://']) {
      if (host.startsWith(prefix)) {
        host = host.substring(prefix.length);
        break;
      }
    }
    if (host.contains('/')) host = host.split('/')[0];
    if (host.contains(':')) host = host.split(':')[0];
    return host;
  }
}

// ─────────────────────────────────────────────────────────────────
// Helper to initialize the foreground service configuration.
// Call this once at app startup (e.g., in DashboardController.onInit).
// ─────────────────────────────────────────────────────────────────
void initMqttForegroundService() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'iuno_mqtt_service',
      channelName: 'iuno IoT Connection',
      channelDescription: 'Keeps MQTT connection alive when app is minimized.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      // Check connection every 30 seconds
      eventAction: ForegroundTaskEventAction.repeat(30000),
      // Do NOT auto-start on boot — stops when app is swiped from recents
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      // Allow WiFi lock to keep network alive
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}
