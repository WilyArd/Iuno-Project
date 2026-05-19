import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';

class MqttService {
  MqttServerClient? client;

  // ✅ Single map of subscriptions: pattern → callback
  // Ini memastikan hanya SATU listener pada client.updates,
  // menghindari bug dimana Dart single-stream membatalkan listener sebelumnya.
  final Map<String, void Function(String topic, String message)> _subscriptions = {};

  void setup(String server, String clientId) {
    client = MqttServerClient(server, clientId);
    client!.port = 1883;
    client!.keepAlivePeriod = 20;
    client!.connectTimeoutPeriod = 5000;
    client!.onDisconnected = _onDisconnected;
    client!.secure = false;
    client!.logging(on: false);

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client!.connectionMessage = connMess;
  }

  Future<bool> connect() async {
    try {
      await client!.connect().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          client!.disconnect();
          throw TimeoutException('MQTT connection timed out');
        },
      );
    } on NoConnectionException catch (e) {
      print('MQTT: NoConnectionException - $e');
      client!.disconnect();
      return false;
    } on SocketException catch (e) {
      print('MQTT: SocketException - $e');
      client!.disconnect();
      return false;
    } on TimeoutException catch (e) {
      print('MQTT: TimeoutException - $e');
      return false;
    } catch (e) {
      print('MQTT: Unknown error - $e');
      client?.disconnect();
      return false;
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT: Connected');

      // ✅ Daftarkan SATU listener global untuk semua incoming messages
      client!.updates!.listen(_onMessage);
      return true;
    } else {
      print('MQTT: Failed - ${client!.connectionStatus!.state}');
      client!.disconnect();
      return false;
    }
  }

  /// Router utama untuk semua pesan MQTT masuk.
  /// Mencocokkan topik dengan semua pattern yang terdaftar dan memanggil callback-nya.
  void _onMessage(List<MqttReceivedMessage<MqttMessage?>>? messages) {
    if (messages == null || messages.isEmpty) return;

    final receivedTopic = messages[0].topic;
    final recMess = messages[0].payload as MqttPublishMessage;
    final payload = MqttPublishPayload.bytesToStringAsString(
      recMess.payload.message,
    );

    // Iterasi semua subscription yang terdaftar
    for (final entry in _subscriptions.entries) {
      if (_topicMatches(entry.key, receivedTopic)) {
        entry.value(receivedTopic, payload);
      }
    }
  }

  void _onDisconnected() {
    print('MQTT: Disconnected');
  }

  /// Subscribe ke sebuah topic pattern.
  /// Callback disimpan di map, dirouting oleh _onMessage.
  void subscribe(
    String topicPattern,
    void Function(String topic, String message) onMessage,
  ) {
    print('MQTT: Subscribing to $topicPattern');
    client!.subscribe(topicPattern, MqttQos.atMostOnce);
    _subscriptions[topicPattern] = onMessage; // ✅ Tidak memanggil .listen() lagi
  }

  /// MQTT wildcard matching (RFC 3.1.1 compliant)
  /// '+' = exactly one segment, '#' = any remaining segments
  bool _topicMatches(String pattern, String topic) {
    if (pattern == topic) return true;
    if (pattern == '#') return true;

    final patternParts = pattern.split('/');
    final topicParts = topic.split('/');

    for (int i = 0; i < patternParts.length; i++) {
      final p = patternParts[i];

      if (p == '#') return true;
      if (i >= topicParts.length) return false;
      if (p == '+') continue;
      if (p != topicParts[i]) return false;
    }

    return patternParts.length == topicParts.length;
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    _subscriptions.clear();
    client?.disconnect();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => 'TimeoutException: $message';
}
