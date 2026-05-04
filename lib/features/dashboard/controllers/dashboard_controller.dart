import 'dart:async';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/mqtt_service.dart';

class DashboardController extends GetxController {
  final mqttService = MqttService();

  // Variabel reactive (observable) untuk UI
  var isBrokerConnected = false.obs;
  var isDeviceConnected = false.obs;
  var isConnecting = false.obs;
  var deviceName = "".obs;
  var temperature = "--".obs;
  var humidity = "--".obs;

  // Target sensor data
  var targetTemperature = 24.0.obs;
  var targetHumidity = 60.0.obs;

  // Historical data for charts
  var temperatureHistory = <FlSpot>[].obs;
  var humidityHistory = <FlSpot>[].obs;
  int _tempCounter = 0;
  int _humidCounter = 0;

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
      temperature.value = "--";
      humidity.value = "--";
      temperatureHistory.clear();
      humidityHistory.clear();
      _tempCounter = 0;
      _humidCounter = 0;
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

      mqttService.subscribe('+/sensor/suhu', (topic, message) {
        String name = topic.split('/')[0].toUpperCase();
        deviceName.value = '$name Sensor Node';
        temperature.value = message;
        _addHistoryData(temperatureHistory, message, true);
        _resetEsp32Timeout();

        // --- NATIVE AI INJECTION ---
        double? currentSuhu = double.tryParse(message);
        if (currentSuhu != null) {
          double newTarget = _calculateTargetSuhu(currentSuhu);
          targetTemperature.value = newTarget;
          // Publish kembali ke MQTT agar hardware mendapat perintah
          mqttService.publish('iuno/ai/target/suhu', newTarget.toString());
        }
      });

      mqttService.subscribe('+/sensor/kelembaban', (topic, message) {
        String name = topic.split('/')[0].toUpperCase();
        deviceName.value = '$name Sensor Node';
        humidity.value = message;
        _addHistoryData(humidityHistory, message, false);
        _resetEsp32Timeout();

        // --- NATIVE AI INJECTION ---
        double? currentKelembaban = double.tryParse(message);
        if (currentKelembaban != null) {
          double newTarget = _calculateTargetKelembaban(currentKelembaban);
          targetHumidity.value = newTarget;
          // Publish kembali ke MQTT agar hardware mendapat perintah
          mqttService.publish(
            'iuno/ai/target/kelembaban',
            newTarget.toString(),
          );
        }
      });
    }
  }

  void _addHistoryData(RxList<FlSpot> history, String message, bool isTemp) {
    double? val = double.tryParse(message);
    if (val != null) {
      double x = isTemp ? _tempCounter.toDouble() : _humidCounter.toDouble();
      history.add(FlSpot(x, val));
      if (history.length > 100) {
        history.removeAt(0);
      }
      if (isTemp) {
        _tempCounter++;
      } else {
        _humidCounter++;
      }
    }
  }

  void _resetEsp32Timeout() {
    // Setiap kali terima pesan, berarti ESP32 online
    isDeviceConnected.value = true;

    // Batalkan timer lama
    _esp32TimeoutTimer?.cancel();

    // Buat timer baru untuk 5 detik (karena ESP32 kirim tiap 2 detik)
    _esp32TimeoutTimer = Timer(const Duration(seconds: 5), () {
      // Jika selama 5 detik tidak ada pesan, anggap ESP32 offline
      isDeviceConnected.value = false;
      deviceName.value = "";
      temperature.value = "--";
      humidity.value = "--";
    });
  }

  @override
  void onClose() {
    _esp32TimeoutTimer?.cancel();
    mqttService.disconnect();
    super.onClose();
  }

  // --- NATIVE AI LOGIC ---
  double _calculateTargetSuhu(double currentSuhu) {
    if (currentSuhu > 28.0) {
      return 24.0;
    } else if (currentSuhu < 22.0) {
      return 25.0;
    } else {
      return currentSuhu;
    }
  }

  double _calculateTargetKelembaban(double currentKelembaban) {
    if (currentKelembaban > 70.0) {
      return 50.0;
    } else if (currentKelembaban < 40.0) {
      return 55.0;
    } else {
      return currentKelembaban;
    }
  }
}
