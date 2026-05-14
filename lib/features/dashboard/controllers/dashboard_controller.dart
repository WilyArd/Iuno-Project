import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
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
    // Sesuaikan dengan broker yang ada di ESP32 Anda
    mqttService.setup(
      'broker.emqx.io',
      'flutter_esp32_client_${DateTime.now().millisecondsSinceEpoch}',
    );

    bool brokerConnected = await mqttService.connect();

    if (brokerConnected) {
      isBrokerConnected.value = true;

      // Subscribe to discovery topic
      mqttService.subscribe('iuno/+/discovery', (topic, message) {
        try {
          final data = jsonDecode(message);
          _handleDiscovery(data);
          _resetEsp32Timeout();
        } catch (e) {
          print('Error parsing discovery message: $e');
        }
      });
    }
  }

  void _handleDiscovery(Map<String, dynamic> data) {
    final newDevice = DeviceWidgetModel.fromJson(data);
    
    // Check if device already exists
    final index = devices.indexWhere((d) => d.id == newDevice.id);
    if (index == -1) {
      devices.add(newDevice);
      
      // Subscribe to its state topic
      if (newDevice.stateTopic.isNotEmpty) {
        mqttService.subscribe(newDevice.stateTopic, (topic, message) {
          newDevice.value.value = message;
          _addHistoryData(newDevice, message);
          _resetEsp32Timeout();
        });
      }
    } else {
      // Update existing
      devices[index] = newDevice;
      // We don't re-subscribe here to avoid duplicates, assuming topic hasn't changed
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
