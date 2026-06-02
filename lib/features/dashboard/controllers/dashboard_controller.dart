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

  @override
  void onInit() {
    super.onInit();
    _initMqtt();
  }

  Future<void> toggleConnection() async {
    if (isBrokerConnected.value) {
      // Manual disconnect
      mqttService.disconnect();
      _esp32TimeoutTimer?.cancel();
      isBrokerConnected.value = false;
      isDeviceConnected.value = false;
      deviceName.value = "";
      devices.clear();
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
      // ESP32 publish ke: iuno/esp32-001/discovery/temp & .../hum
      // Pattern '#' setelah discovery agar tangkap semua sensor
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
      // (agar tidak harus tunggu 30 detik interval re-discovery ESP32)
      Future.delayed(const Duration(seconds: 2), () {
        mqttService.publish('iuno/device/cmd', 'rediscover');
        print('MQTT: Sent rediscover command to ESP32');
      });
    }
  }

  void _handleDiscovery(Map<String, dynamic> data) {
    final id = data['id'] ?? '';
    if (id.isEmpty) return;

    // Cek apakah device sudah ada
    final index = devices.indexWhere((d) => d.id == id);

    if (index == -1) {
      // Device baru → tambahkan dan subscribe ke state topic-nya
      final newDevice = DeviceWidgetModel.fromJson(data);
      devices.add(newDevice);
      print('MQTT: New device discovered: ${newDevice.name} (${newDevice.id})');

      if (newDevice.stateTopic.isNotEmpty) {
        // ✅ Closure menangkap `newDevice` yang sama dengan yg ada di list
        mqttService.subscribe(newDevice.stateTopic, (topic, message) {
          newDevice.value.value = message.trim();
          _addHistoryData(newDevice, message.trim());
          _resetEsp32Timeout();
        });
      }
    }
    // Jika sudah ada, jangan ganti object-nya agar subscription tetap valid
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
    // Setiap kali terima pesan, berarti ESP32 online
    isDeviceConnected.value = true;

    // Batalkan timer lama
    _esp32TimeoutTimer?.cancel();

    // Buat timer baru untuk 10 detik
    _esp32TimeoutTimer = Timer(const Duration(seconds: 10), () {
      // Jika selama 10 detik tidak ada pesan, anggap ESP32 offline
      isDeviceConnected.value = false;
      for (var device in devices) {
        device.value.value = "--";
      }
    });
  }

  void sendCommand(DeviceWidgetModel device, String command) {
    if (device.commandTopic.isNotEmpty) {
      mqttService.publish(device.commandTopic, command);
    }
  }

  @override
  void onClose() {
    _esp32TimeoutTimer?.cancel();
    mqttService.disconnect();
    super.onClose();
  }
}
