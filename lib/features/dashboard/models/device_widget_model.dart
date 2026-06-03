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
    final model = DeviceWidgetModel(
      id: json['id'] ?? '',
      type: json['type'] ?? 'sensor',
      name: json['name'] ?? 'Unknown Device',
      unit: json['unit'] ?? '',
      stateTopic: json['state_topic'] ?? '',
      commandTopic: json['command_topic'] ?? '',
    );
    // Restore last known value so switch/relay shows the correct persisted state
    final savedValue = json['last_value'] as String?;
    if (savedValue != null && savedValue.isNotEmpty) {
      model.value.value = savedValue;
    }
    return model;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'unit': unit,
      'state_topic': stateTopic,
      'command_topic': commandTopic,
      // Persist the last known value so relay/switch state survives app restarts
      'last_value': value.value,
    };
  }
}
