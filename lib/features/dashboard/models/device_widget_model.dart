import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';

class DeviceWidgetModel {
  final String id;
  final String type; // 'sensor', 'switch', 'button'
  final String name;
  final String unit;
  final String stateTopic;
  final String commandTopic;
  
  // Reactive properties for the UI
  var value = "--".obs;
  var targetValue = 0.0.obs;
  var history = <FlSpot>[].obs;
  int historyCounter = 0;

  DeviceWidgetModel({
    required this.id,
    required this.type,
    required this.name,
    required this.unit,
    required this.stateTopic,
    required this.commandTopic,
  });

  factory DeviceWidgetModel.fromJson(Map<String, dynamic> json) {
    return DeviceWidgetModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'sensor',
      name: json['name'] ?? 'Unknown Device',
      unit: json['unit'] ?? '',
      stateTopic: json['state_topic'] ?? '',
      commandTopic: json['command_topic'] ?? '',
    );
  }
}
