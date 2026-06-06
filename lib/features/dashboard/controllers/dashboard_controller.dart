import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/mqtt_service.dart';
import '../../../core/services/mqtt_foreground_service.dart';
import '../models/device_widget_model.dart';

class DashboardController extends GetxController with WidgetsBindingObserver {
  final mqttService = MqttService();

  // Variabel reactive (observable) untuk UI
  var isBrokerConnected = false.obs;
  var isDeviceConnected = false.obs;
  var isConnecting = false.obs;
  var deviceName = "".obs;

  // Dynamic devices list
  var devices = <DeviceWidgetModel>[].obs;

  Timer? _esp32TimeoutTimer;

  // Flag to check if we are in demo simulation mode
  var isDemoMode = true.obs;
  Timer? _simulationTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initForegroundService();
    // ⚠️ Run sequentially: prefs must be fully loaded BEFORE MQTT connects,
    // otherwise the re-subscription loop runs against an empty device list.
    _initAll();
  }

  /// Sequential initialization: load persisted state → start sim → connect MQTT.
  Future<void> _initAll() async {
    await _loadDevicesFromPrefs();
    _startSimulation();
    await _initMqtt();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When the foreground service is active, it maintains the MQTT socket.
    // We no longer disconnect on pause — the service does the keep-alive.
    // The service stops automatically when the user swipes the app from recents
    // (android:stopWithTask="true" in AndroidManifest).
    if (state == AppLifecycleState.resumed) {
      // App is foregrounded — sync UI state with actual connection state
      _checkAndReconnectIfNeeded();
    }
  }

  void _checkAndReconnectIfNeeded() {
    if (!isBrokerConnected.value && !isConnecting.value) {
      // isConnecting is now managed inside _initMqtt itself
      _initMqtt();
    }
  }

  /// [M-2] Validasi format MQTT topic: tidak boleh mengandung wildcard saat publish
  bool _isValidMqttTopic(String topic, {bool allowWildcard = false}) {
    if (topic.isEmpty) return true;
    if (!allowWildcard && (topic.contains('#') || topic.contains('+'))) return false;
    if (topic.startsWith('/') || topic.endsWith('/')) return false;
    if (topic.length > 256) return false;
    return true;
  }

  Future<void> _saveDevicesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nonDemoDevices = devices.where((d) => !d.id.startsWith('demo_')).toList();
      final list = nonDemoDevices.map((d) => jsonEncode(d.toJson())).toList();
      await prefs.setStringList('custom_devices_list', list);
      await prefs.setBool('devices_is_demo_mode', isDemoMode.value);
    } catch (e) {
      debugPrint('Error saving devices: $e');
    }
  }

  Future<void> _loadDevicesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('custom_devices_list');
      final wasDemo = prefs.getBool('devices_is_demo_mode') ?? true;
      
      devices.clear();
      isDemoMode.value = wasDemo;
      
      if (wasDemo) {
        _loadDemoDevices();
      }
      
      if (list != null && list.isNotEmpty) {
        for (var str in list) {
          final map = jsonDecode(str);
          final d = DeviceWidgetModel.fromJson(map);
          
          // Seed some initial history spots if empty so the sparklines look gorgeous
          if (d.type == 'sensor' && d.history.isEmpty) {
            final double baseVal = double.tryParse(d.value.value) ?? 25.0;
            for (int i = 0; i < 15; i++) {
              d.history.add(FlSpot(i.toDouble(), baseVal + (i % 3) * 0.5));
            }
            d.historyCounter = 15;
          }
          devices.add(d);
        }
      }
    } catch (e) {
      debugPrint('Error loading devices: $e');
      if (isDemoMode.value) {
        _loadDemoDevices();
      }
    }
  }

  void _loadDemoDevices() {
    isDemoMode.value = true;
    devices.removeWhere((d) => d.id.startsWith('demo_'));
    
    // Default Device group
    final temp = DeviceWidgetModel(
      id: 'demo_dht22_temp',
      type: 'sensor',
      name: 'Suhu DHT22',
      unit: '°C',
      stateTopic: 'iuno/demo/temp',
      commandTopic: '',
      deviceGroup: 'Default Device',
    );
    temp.value.value = '27.4';
    
    final hum = DeviceWidgetModel(
      id: 'demo_dht22_hum',
      type: 'sensor',
      name: 'Kelembaban DHT22',
      unit: '%',
      stateTopic: 'iuno/demo/hum',
      commandTopic: '',
      deviceGroup: 'Default Device',
    );
    hum.value.value = '62.8';
    
    final soil = DeviceWidgetModel(
      id: 'demo_soil',
      type: 'sensor',
      name: 'Kelembaban Tanah',
      unit: '%',
      stateTopic: 'iuno/demo/soil',
      commandTopic: '',
      deviceGroup: 'Default Device',
    );
    soil.value.value = '48.5';

    final press = DeviceWidgetModel(
      id: 'demo_bmp280_press',
      type: 'sensor',
      name: 'Tekanan BMP280',
      unit: 'hPa',
      stateTopic: 'iuno/demo/press',
      commandTopic: '',
      deviceGroup: 'Default Device',
    );
    press.value.value = '1013';
    
    final dist = DeviceWidgetModel(
      id: 'demo_distance',
      type: 'sensor',
      name: 'Sensor Jarak',
      unit: 'cm',
      stateTopic: 'iuno/demo/dist',
      commandTopic: '',
      deviceGroup: 'Default Device',
    );
    dist.value.value = '24.5';

    final light = DeviceWidgetModel(
      id: 'demo_light',
      type: 'sensor',
      name: 'Intensitas Cahaya',
      unit: 'lx',
      stateTopic: 'iuno/demo/light',
      commandTopic: '',
      deviceGroup: 'Default Device',
    );
    light.value.value = '420';
    
    final relay = DeviceWidgetModel(
      id: 'demo_relay_switch',
      type: 'switch',
      name: 'Relay Switch',
      unit: '',
      stateTopic: 'iuno/demo/relay/state',
      commandTopic: 'iuno/demo/relay/cmd',
      deviceGroup: 'Default Device',
    );
    relay.value.value = 'OFF';
    
    final button = DeviceWidgetModel(
      id: 'demo_relay_trigger',
      type: 'button',
      name: 'Manual Relay',
      unit: '',
      stateTopic: '',
      commandTopic: 'iuno/demo/relay/btn',
      deviceGroup: 'Default Device',
    );
    button.value.value = 'READY';

    // Seed some initial history spots for graphs to look gorgeous immediately!
    for (int i = 0; i < 15; i++) {
      temp.history.add(FlSpot(i.toDouble(), 26.0 + (i % 3) * 0.5 + (i % 2) * 0.2));
      hum.history.add(FlSpot(i.toDouble(), 60.0 + (i % 4) * 0.8 - (i % 3) * 0.3));
      press.history.add(FlSpot(i.toDouble(), 1010.0 + (i % 3) * 1.5 - (i % 2) * 0.5));
      dist.history.add(FlSpot(i.toDouble(), 15.0 + (i % 5) * 2.5));
      light.history.add(FlSpot(i.toDouble(), 380.0 + (i % 6) * 15.0 - (i % 4) * 5.0));
      soil.history.add(FlSpot(i.toDouble(), 45.0 + (i % 3) * 2.0 + (i % 2) * 0.8));
    }
    temp.historyCounter = 15;
    hum.historyCounter = 15;
    press.historyCounter = 15;
    dist.historyCounter = 15;
    light.historyCounter = 15;
    soil.historyCounter = 15;

    devices.addAll([temp, hum, soil, press, dist, light, relay, button]);
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!isDemoMode.value) return;

      for (var d in devices) {
        if (d.type == 'sensor') {
          final name = d.name.toLowerCase();
          final currentVal = double.tryParse(d.value.value) ?? 20.0;
          double nextVal;
          
          if (name.contains('temp') || name.contains('suhu')) {
            nextVal = (currentVal + (DateTime.now().second % 3 == 0 ? 0.1 : -0.1)).clamp(25.0, 31.0);
            d.value.value = nextVal.toStringAsFixed(1);
          } else if (name.contains('hum') || name.contains('kelembaban') && !name.contains('tanah')) {
            nextVal = (currentVal + (DateTime.now().second % 2 == 0 ? 0.3 : -0.2)).clamp(55.0, 75.0);
            d.value.value = nextVal.toStringAsFixed(1);
          } else if (name.contains('press') || name.contains('tekanan')) {
            nextVal = (currentVal + (DateTime.now().second % 3 == 0 ? 0.4 : -0.3)).clamp(990.0, 1025.0);
            d.value.value = nextVal.toStringAsFixed(0);
          } else if (name.contains('dist') || name.contains('jarak')) {
            nextVal = (currentVal + (DateTime.now().second % 4 == 0 ? 1.5 : -1.2)).clamp(5.0, 80.0);
            d.value.value = nextVal.toStringAsFixed(1);
          } else if (name.contains('light') || name.contains('cahaya') || name.contains('lux') || name.contains('ldr')) {
            nextVal = (currentVal + (DateTime.now().second % 3 == 0 ? 12.0 : -10.0)).clamp(100.0, 900.0);
            d.value.value = nextVal.toStringAsFixed(0);
          } else if (name.contains('soil') || name.contains('tanah')) {
            nextVal = (currentVal + (DateTime.now().second % 2 == 0 ? 0.8 : -0.6)).clamp(30.0, 90.0);
            d.value.value = nextVal.toStringAsFixed(1);
          } else {
            // General fallback sensor random walk
            nextVal = (currentVal + (DateTime.now().second % 2 == 0 ? 0.5 : -0.4)).clamp(0.0, 100.0);
            d.value.value = nextVal.toStringAsFixed(1);
          }
          _addHistoryData(d, d.value.value);
        }
      }
    });
  }

  void addCustomDevice({
    required String name,
    required String type,
    required String unit,
    required String stateTopic,
    required String commandTopic,
    required String deviceGroup,
  }) {
    final id = 'custom_${type}_${DateTime.now().millisecondsSinceEpoch}';
    final newDevice = DeviceWidgetModel(
      id: id,
      type: type,
      name: name,
      unit: unit,
      stateTopic: stateTopic,
      commandTopic: commandTopic,
      deviceGroup: deviceGroup.trim().isNotEmpty ? deviceGroup.trim() : 'My Devices',
    );

    if (type == 'sensor') {
      newDevice.value.value = '25.0';
      for (int i = 0; i < 15; i++) {
        newDevice.history.add(FlSpot(i.toDouble(), 20.0 + (i % 3) * 1.0));
      }
      newDevice.historyCounter = 15;
    } else if (type == 'switch') {
      newDevice.value.value = 'OFF';
    } else {
      newDevice.value.value = 'READY';
    }

    devices.add(newDevice);
    _saveDevicesToPrefs();

    // [M-2] Validasi topic sebelum subscribe
    // If MQTT broker is active and connected, subscribe to state topic immediately!
    if (isBrokerConnected.value && stateTopic.isNotEmpty && _isValidMqttTopic(stateTopic, allowWildcard: false)) {
      mqttService.subscribe(stateTopic, (topic, message) {
        newDevice.value.value = message.trim();
        _addHistoryData(newDevice, message.trim());
        // Persist updated state from MQTT
        _saveDevicesToPrefs();
        _resetEsp32Timeout();
      });
    }
  }

  void renameDevice(String id, String newName, String newGroup) {
    final index = devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final oldDevice = devices[index];
      final newDevice = DeviceWidgetModel(
        id: oldDevice.id,
        type: oldDevice.type,
        name: newName,
        unit: oldDevice.unit,
        stateTopic: oldDevice.stateTopic,
        commandTopic: oldDevice.commandTopic,
        deviceGroup: newGroup.trim().isNotEmpty ? newGroup.trim() : 'My Devices',
      );
      
      newDevice.value.value = oldDevice.value.value;
      newDevice.targetValue.value = oldDevice.targetValue.value;
      newDevice.history.assignAll(oldDevice.history);
      newDevice.historyCounter = oldDevice.historyCounter;
      
      devices[index] = newDevice;
      devices.refresh();
      _saveDevicesToPrefs();
    }
  }

  void renameDeviceGroup(String oldGroupName, String newGroupName) {
    final trimmedNew = newGroupName.trim();
    if (trimmedNew.isEmpty) return;
    
    bool updated = false;
    for (int i = 0; i < devices.length; i++) {
      if (devices[i].deviceGroup == oldGroupName) {
        final old = devices[i];
        final updatedDevice = DeviceWidgetModel(
          id: old.id,
          type: old.type,
          name: old.name,
          unit: old.unit,
          stateTopic: old.stateTopic,
          commandTopic: old.commandTopic,
          deviceGroup: trimmedNew,
        );
        updatedDevice.value.value = old.value.value;
        updatedDevice.targetValue.value = old.targetValue.value;
        updatedDevice.history.assignAll(old.history);
        updatedDevice.historyCounter = old.historyCounter;
        
        devices[i] = updatedDevice;
        updated = true;
      }
    }
    
    if (updated) {
      devices.refresh();
      _saveDevicesToPrefs();
    }
  }

  void deleteDevice(String id) {
    devices.removeWhere((d) => d.id == id);
    _saveDevicesToPrefs();
  }

  void setDemoMode(bool val) {
    isDemoMode.value = val;
    if (val) {
      if (isBrokerConnected.value) {
        _stopForegroundService();
        mqttService.disconnect();
        isBrokerConnected.value = false;
        isDeviceConnected.value = false;
        deviceName.value = "";
      }
      _loadDemoDevices();
      _startSimulation();
    } else {
      _simulationTimer?.cancel();
      devices.removeWhere((d) => d.id.startsWith('demo_'));
    }
    _saveDevicesToPrefs();
  }

  Future<void> toggleConnection() async {
    if (isBrokerConnected.value) {
      // Manual disconnect — stop foreground service and MQTT
      await _stopForegroundService();
      mqttService.disconnect();
      _esp32TimeoutTimer?.cancel();
      isBrokerConnected.value = false;
      isDeviceConnected.value = false;
      deviceName.value = "";
      if (isDemoMode.value) {
        _loadDemoDevices();
        _startSimulation();
      } else {
        for (var device in devices) {
          device.value.value = "--";
        }
      }
    } else {
      // Manual connect — _initMqtt manages isConnecting internally
      await _initMqtt();
    }
  }

  Future<void> _initMqtt() async {
    // Guard against concurrent calls (e.g. onInit + didChangeAppLifecycleState)
    if (isConnecting.value) return;
    isConnecting.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final protocol = prefs.getString('connection_protocol') ?? 'MQTT';
      if (protocol == 'HTTP') {
        debugPrint('DashboardController: HTTP protocol selected. Skipping MQTT setup.');
        isBrokerConnected.value = false;
        return;
      }

    final bool secure = prefs.getBool('mqtt_use_tls') ?? false;
    String host = prefs.getString('mqtt_host') ?? '192.168.10.3';
    if (secure) {
      final tlsHost = prefs.getString('mqtt_tls_host') ?? '';
      if (tlsHost.isNotEmpty) {
        host = tlsHost;
      }
    }

    // Sanitize host string (remove schema prefixes and trailing ports/slashes)
    host = host.trim();
    if (host.startsWith('mqtt://')) host = host.substring(7);
    if (host.startsWith('mqtts://')) host = host.substring(8);
    if (host.startsWith('ssl://')) host = host.substring(6);
    if (host.startsWith('tcp://')) host = host.substring(6);
    if (host.startsWith('wss://')) host = host.substring(6);
    if (host.startsWith('ws://')) host = host.substring(5);

    if (host.contains('/')) {
      host = host.split('/')[0];
    }
    if (host.contains(':')) {
      host = host.split(':')[0];
    }

    final int port = prefs.getInt('mqtt_port') ?? 1883;
    final String username = prefs.getString('mqtt_username') ?? '';
    final String password = prefs.getString('mqtt_password') ?? '';

    // [M-1 FIX] Debug info hanya tampil saat mode debug
    debugPrint('MQTT DEBUG: host="$host" port=$port secure=$secure');
    debugPrint('MQTT DEBUG: username="${username.isNotEmpty ? username : "(empty)"}" password="${password.isNotEmpty ? "(set)" : "(empty)"}"');

    mqttService.setup(
      host,
      'flutter_iuno_client_${DateTime.now().millisecondsSinceEpoch}',
      port: port,
      secure: secure,
    );

    bool brokerConnected = await mqttService.connect(
      username: username.isNotEmpty ? username : null,
      password: password.isNotEmpty ? password : null,
    );

      if (brokerConnected) {
        isBrokerConnected.value = true;
        // Start the foreground service so MQTT stays alive in background
        _startForegroundService();

        // If broker connected, disable demo mode automatically and remove simulated demo widgets
        if (isDemoMode.value) {
          isDemoMode.value = false;
          _simulationTimer?.cancel();
          devices.removeWhere((d) => d.id.startsWith('demo_'));
          _saveDevicesToPrefs();
        }

        // ─── Re-subscribe persisted devices ─────────────────────────────
        // When the app is restarted, devices are loaded from SharedPreferences.
        // The MQTT subscriptions are lost on restart, so we re-establish them
        // here before sending 'rediscover', so state updates are not missed.
        for (final device in devices) {
          if (device.stateTopic.isNotEmpty) {
            mqttService.subscribe(device.stateTopic, (topic, message) {
              device.value.value = message.trim();
              _addHistoryData(device, message.trim());
              _saveDevicesToPrefs();
              _resetEsp32Timeout();
            });
          }
        }

        // ✅ Subscribe ke pattern yang cocok dengan ESP32:
        mqttService.subscribe('iuno/+/discovery/#', (topic, message) {
          try {
            final data = jsonDecode(message);
            _handleDiscovery(topic, data);
            _resetEsp32Timeout();
          } catch (e) {
            debugPrint('Error parsing discovery: $e');
          }
        });

        // ✅ Setelah connect, minta ESP32 kirim ulang discovery segera
        Future.delayed(const Duration(seconds: 2), () {
          mqttService.publish('iuno/device/cmd', 'rediscover');
          debugPrint('MQTT: Sent rediscover command to ESP32');
        });
      }
    } finally {
      isConnecting.value = false;
    }
  }

  void _handleDiscovery(String topic, Map<String, dynamic> data) {
    // [M-3 FIX] Validasi dan sanitasi payload dari broker sebelum digunakan
    final id = (data['id'] as String? ?? '').trim();
    if (id.isEmpty || id.length > 64) return; // Tolak ID kosong atau terlalu panjang

    final name = (data['name'] as String? ?? 'Device').trim();
    if (name.length > 100) return; // Tolak nama yang terlalu panjang

    final stateTopic = (data['stateTopic'] as String? ?? '').trim();
    final cmdTopic = (data['commandTopic'] as String? ?? '').trim();

    // Validasi topic hanya berisi karakter yang valid (bukan wildcard berbahaya pada publish)
    if (stateTopic.isNotEmpty && !_isValidMqttTopic(stateTopic)) return;
    if (cmdTopic.isNotEmpty && !_isValidMqttTopic(cmdTopic)) return;

    // Batasi jumlah device maksimum untuk mencegah resource exhaustion
    if (devices.length >= 50) {
      debugPrint('MQTT: Device limit reached (50). Ignoring new discovery from $id');
      return;
    }

    // If we receive a real discovery message, clear all demo/simulated devices first!
    if (isDemoMode.value) {
      isDemoMode.value = false;
      _simulationTimer?.cancel();
      devices.removeWhere((d) => d.id.startsWith('demo_'));
    }

    // Default group to 'Default Device' if not specified in payload
    const defaultGroup = 'Default Device';
    
    // Inject device group from MQTT payload or topic
    final payloadWithGroup = Map<String, dynamic>.from(data);
    if (!payloadWithGroup.containsKey('device_group')) {
      payloadWithGroup['device_group'] = defaultGroup;
    }

    // Cek apakah device sudah ada
    final index = devices.indexWhere((d) => d.id == id);

    if (index == -1) {
      // Device baru → tambahkan dan subscribe ke state topic-nya
      final newDevice = DeviceWidgetModel.fromJson(payloadWithGroup);
      devices.add(newDevice);
      debugPrint('MQTT: New device discovered: ${newDevice.name} (${newDevice.id}) under group: ${newDevice.deviceGroup}');

      if (newDevice.stateTopic.isNotEmpty) {
        mqttService.subscribe(newDevice.stateTopic, (topic, message) {
          newDevice.value.value = message.trim();
          _addHistoryData(newDevice, message.trim());
          // Persist updated state (e.g. relay ON confirmation from ESP32)
          _saveDevicesToPrefs();
          _resetEsp32Timeout();
        });
      }
    } else {
      // Device sudah ada (mungkin load dari prefs atau re-discovery).
      // Pastikan subscription state topic-nya aktif
      final existingDevice = devices[index];
      if (existingDevice.stateTopic.isNotEmpty) {
        mqttService.subscribe(existingDevice.stateTopic, (topic, message) {
          existingDevice.value.value = message.trim();
          _addHistoryData(existingDevice, message.trim());
          _saveDevicesToPrefs();
          _resetEsp32Timeout();
        });
        debugPrint('MQTT: Re-subscribed state topic for existing device: ${existingDevice.name}');
      }
    }
  }

  void _addHistoryData(DeviceWidgetModel device, String message) {
    if (device.type != 'sensor') return;
    double? val = double.tryParse(message);
    if (val != null) {
      device.history.add(FlSpot(device.historyCounter.toDouble(), val));
      if (device.history.length > 100) {
        device.history.removeAt(0);
      }
      device.historyCounter++;
    }
  }

  void _resetEsp32Timeout() {
    isDeviceConnected.value = true;
    _esp32TimeoutTimer?.cancel();
    _esp32TimeoutTimer = Timer(const Duration(seconds: 10), () {
      isDeviceConnected.value = false;
      if (!isDemoMode.value) {
        for (var device in devices) {
          device.value.value = "--";
        }
      }
    });
  }

  /// Called when the user physically toggles a switch on the dashboard.
  /// Only sends command (and updates UI) when the broker is connected.
  /// If disconnected, shows a snackbar so the user knows the toggle was ignored.
  void toggleSwitch(DeviceWidgetModel device, bool newValue) {
    if (!isBrokerConnected.value) {
      Get.snackbar(
        '',
        'Tidak terhubung ke broker. Sambungkan terlebih dahulu.',
        titleText: const SizedBox.shrink(),
        messageText: Text(
          'Tidak terhubung ke broker. Sambungkan dulu untuk mengontrol ${device.name}.',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F172A),
        colorText: Colors.white,
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.wifi_off_rounded, color: Colors.white),
      );
      return; // Do NOT update state — broker is offline, relay physically unchanged
    }
    final command = newValue ? 'ON' : 'OFF';
    device.value.value = command; // Optimistic update (broker is confirmed connected)
    _saveDevicesToPrefs();
    sendCommand(device, command);
  }

  void sendCommand(DeviceWidgetModel device, String command) {
    if (isBrokerConnected.value && device.commandTopic.isNotEmpty) {
      try {
        mqttService.publish(device.commandTopic, command);
      } catch (e) {
        debugPrint('Error publishing MQTT command: $e');
      }
    } else {
      debugPrint('MQTT Broker is disconnected. Command "$command" to "${device.commandTopic}" was simulated locally.');
    }
  }

  // ─── Foreground Service helpers ───────────────────────────────

  void _initForegroundService() {
    if (!Platform.isAndroid) return;
    // Configure the foreground service (notification channel, options, etc.)
    initMqttForegroundService();
    // Listen for events sent from the background isolate (TaskHandler)
    FlutterForegroundTask.addTaskDataCallback(_onForegroundServiceData);
  }

  void _onForegroundServiceData(Object data) {
    if (data is Map) {
      final event = data['event'] as String?;
      if (event == 'connection_changed') {
        final connected = data['connected'] as bool? ?? false;
        // Update UI state based on background connection result
        isBrokerConnected.value = connected;
        if (!connected) isDeviceConnected.value = false;
      }
    }
  }

  Future<void> _startForegroundService() async {
    if (!Platform.isAndroid) return;
    // Request notification permission (Android 13+)
    final notifPerm = await FlutterForegroundTask.checkNotificationPermission();
    if (notifPerm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 1001,
        notificationTitle: 'iuno',
        notificationText: 'Connected • Monitoring IoT',
        callback: mqttForegroundServiceCallback,
      );
    }
  }

  Future<void> _stopForegroundService() async {
    if (!Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundServiceData);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundServiceData);
    _simulationTimer?.cancel();
    _esp32TimeoutTimer?.cancel();
    mqttService.disconnect();
    super.onClose();
  }
}
