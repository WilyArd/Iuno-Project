import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/mqtt_service.dart';
import '../models/device_widget_model.dart';

class DashboardController extends GetxController {
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
    _loadDevicesFromPrefs();
    _startSimulation();
    _initMqtt();
  }

  Future<void> _saveDevicesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = devices.map((d) => jsonEncode(d.toJson())).toList();
      await prefs.setStringList('custom_devices_list', list);
      await prefs.setBool('devices_is_demo_mode', isDemoMode.value);
    } catch (e) {
      print('Error saving devices: $e');
    }
  }

  Future<void> _loadDevicesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('custom_devices_list');
      final wasDemo = prefs.getBool('devices_is_demo_mode') ?? true;
      
      if (list != null && list.isNotEmpty) {
        devices.clear();
        isDemoMode.value = wasDemo;
        
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
      } else {
        _loadDemoDevices();
      }
    } catch (e) {
      print('Error loading devices: $e');
      _loadDemoDevices();
    }
  }

  void _loadDemoDevices() {
    isDemoMode.value = true;
    devices.clear();
    
    final temp = DeviceWidgetModel(
      id: 'demo_dht22_temp',
      type: 'sensor',
      name: 'Suhu DHT22',
      unit: '°C',
      stateTopic: 'iuno/demo/temp',
      commandTopic: '',
    );
    temp.value.value = '27.4';
    
    final hum = DeviceWidgetModel(
      id: 'demo_dht22_hum',
      type: 'sensor',
      name: 'Kelembaban DHT22',
      unit: '%',
      stateTopic: 'iuno/demo/hum',
      commandTopic: '',
    );
    hum.value.value = '62.8';
    
    final dist = DeviceWidgetModel(
      id: 'demo_distance',
      type: 'sensor',
      name: 'Sensor Jarak',
      unit: 'cm',
      stateTopic: 'iuno/demo/dist',
      commandTopic: '',
    );
    dist.value.value = '24.5';

    final light = DeviceWidgetModel(
      id: 'demo_light',
      type: 'sensor',
      name: 'Intensitas Cahaya',
      unit: 'lx',
      stateTopic: 'iuno/demo/light',
      commandTopic: '',
    );
    light.value.value = '420';

    final soil = DeviceWidgetModel(
      id: 'demo_soil',
      type: 'sensor',
      name: 'Kelembaban Tanah',
      unit: '%',
      stateTopic: 'iuno/demo/soil',
      commandTopic: '',
    );
    soil.value.value = '48.5';
    
    final relay = DeviceWidgetModel(
      id: 'demo_relay_switch',
      type: 'switch',
      name: 'Relay Switch',
      unit: '',
      stateTopic: 'iuno/demo/relay/state',
      commandTopic: 'iuno/demo/relay/cmd',
    );
    relay.value.value = 'OFF';
    
    final button = DeviceWidgetModel(
      id: 'demo_relay_trigger',
      type: 'button',
      name: 'Manual Relay',
      unit: '',
      stateTopic: '',
      commandTopic: 'iuno/demo/relay/btn',
    );
    button.value.value = 'READY';

    // Seed some initial history spots for graphs to look gorgeous immediately!
    for (int i = 0; i < 15; i++) {
      temp.history.add(FlSpot(i.toDouble(), 26.0 + (i % 3) * 0.5 + (i % 2) * 0.2));
      hum.history.add(FlSpot(i.toDouble(), 60.0 + (i % 4) * 0.8 - (i % 3) * 0.3));
      dist.history.add(FlSpot(i.toDouble(), 15.0 + (i % 5) * 2.5));
      light.history.add(FlSpot(i.toDouble(), 380.0 + (i % 6) * 15.0 - (i % 4) * 5.0));
      soil.history.add(FlSpot(i.toDouble(), 45.0 + (i % 3) * 2.0 + (i % 2) * 0.8));
    }
    temp.historyCounter = 15;
    hum.historyCounter = 15;
    dist.historyCounter = 15;
    light.historyCounter = 15;
    soil.historyCounter = 15;

    devices.addAll([temp, hum, dist, light, soil, relay, button]);
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
  }) {
    final id = 'custom_${type}_${DateTime.now().millisecondsSinceEpoch}';
    final newDevice = DeviceWidgetModel(
      id: id,
      type: type,
      name: name,
      unit: unit,
      stateTopic: stateTopic,
      commandTopic: commandTopic,
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

    // If MQTT broker is active and connected, subscribe to state topic immediately!
    if (isBrokerConnected.value && stateTopic.isNotEmpty) {
      mqttService.subscribe(stateTopic, (topic, message) {
        newDevice.value.value = message.trim();
        _addHistoryData(newDevice, message.trim());
        _resetEsp32Timeout();
      });
    }
  }

  void renameDevice(String id, String newName) {
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

  void deleteDevice(String id) {
    devices.removeWhere((d) => d.id == id);
    _saveDevicesToPrefs();
  }

  void setDemoMode(bool val) {
    isDemoMode.value = val;
    if (val) {
      _loadDemoDevices();
      _startSimulation();
    } else {
      devices.clear();
      _simulationTimer?.cancel();
    }
    _saveDevicesToPrefs();
  }

  Future<void> toggleConnection() async {
    if (isBrokerConnected.value) {
      // Manual disconnect
      mqttService.disconnect();
      _esp32TimeoutTimer?.cancel();
      isBrokerConnected.value = false;
      isDeviceConnected.value = false;
      deviceName.value = "";
      _loadDemoDevices();
      _startSimulation();
    } else {
      // Manual connect
      if (isConnecting.value) return;
      isConnecting.value = true;
      await _initMqtt();
      isConnecting.value = false;
    }
  }

  Future<void> _initMqtt() async {
    final prefs = await SharedPreferences.getInstance();
    final protocol = prefs.getString('connection_protocol') ?? 'MQTT';
    if (protocol == 'HTTP') {
      print('DashboardController: HTTP protocol selected. Skipping MQTT setup.');
      isBrokerConnected.value = false;
      return;
    }

    final String host = prefs.getString('mqtt_host') ?? '192.168.10.3';
    final int port = prefs.getInt('mqtt_port') ?? 1883;
    final bool secure = prefs.getBool('mqtt_use_tls') ?? false;

    mqttService.setup(
      host,
      'flutter_iuno_client_${DateTime.now().millisecondsSinceEpoch}',
      port: port,
      secure: secure,
    );

    bool brokerConnected = await mqttService.connect();

    if (brokerConnected) {
      isBrokerConnected.value = true;

      // ✅ Subscribe ke pattern yang cocok dengan ESP32:
      mqttService.subscribe('iuno/+/discovery/#', (topic, message) {
        try {
          final data = jsonDecode(message);
          _handleDiscovery(data);
          _resetEsp32Timeout();
        } catch (e) {
          print('Error parsing discovery: $e');
        }
      });

      // ✅ Setelah connect, minta ESP32 kirim ulang discovery segera
      Future.delayed(const Duration(seconds: 2), () {
        mqttService.publish('iuno/device/cmd', 'rediscover');
        print('MQTT: Sent rediscover command to ESP32');
      });
    }
  }

  void _handleDiscovery(Map<String, dynamic> data) {
    final id = data['id'] ?? '';
    if (id.isEmpty) return;

    // If we receive a real discovery message, clear all demo/simulated devices first!
    if (isDemoMode.value) {
      devices.clear();
      isDemoMode.value = false;
      _simulationTimer?.cancel();
    }

    // Cek apakah device sudah ada
    final index = devices.indexWhere((d) => d.id == id);

    if (index == -1) {
      // Device baru → tambahkan dan subscribe ke state topic-nya
      final newDevice = DeviceWidgetModel.fromJson(data);
      devices.add(newDevice);
      print('MQTT: New device discovered: ${newDevice.name} (${newDevice.id})');

      if (newDevice.stateTopic.isNotEmpty) {
        mqttService.subscribe(newDevice.stateTopic, (topic, message) {
          newDevice.value.value = message.trim();
          _addHistoryData(newDevice, message.trim());
          _resetEsp32Timeout();
        });
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

  void sendCommand(DeviceWidgetModel device, String command) {
    if (isBrokerConnected.value && device.commandTopic.isNotEmpty) {
      try {
        mqttService.publish(device.commandTopic, command);
      } catch (e) {
        print('Error publishing MQTT command: $e');
      }
    } else {
      print('MQTT Broker is disconnected. Command "${command}" to "${device.commandTopic}" was simulated locally.');
    }
  }

  @override
  void onClose() {
    _simulationTimer?.cancel();
    _esp32TimeoutTimer?.cancel();
    mqttService.disconnect();
    super.onClose();
  }
}
