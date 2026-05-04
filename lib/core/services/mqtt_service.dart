import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';

class MqttService {
  MqttServerClient? client;

  // Setup client
  void setup(String server, String clientId) {
    client = MqttServerClient(server, clientId);
    client!.port = 1883;
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = onDisconnected;
    client!.secure = false;
    client!.logging(on: false);

    // Add connection message
    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    print('MQTT: Connecting....');
    client!.connectionMessage = connMess;
  }

  // Connect to server
  Future<bool> connect() async {
    try {
      print('MQTT: Start connect...');
      await client!.connect();
    } on NoConnectionException catch (e) {
      print('MQTT: NoConnectionException - $e');
      client!.disconnect();
      return false;
    } on SocketException catch (e) {
      print('MQTT: SocketException - $e');
      client!.disconnect();
      return false;
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT: Connected');
      return true;
    } else {
      print('MQTT: Failed with status ${client!.connectionStatus!.state}');
      client!.disconnect();
      return false;
    }
  }

  void onDisconnected() {
    print('MQTT: Disconnected');
  }

  void subscribe(
    String topicPattern,
    void Function(String topic, String message) onMessage,
  ) {
    print('MQTT: Subscribing to the $topicPattern topic');
    client!.subscribe(topicPattern, MqttQos.atMostOnce);
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final receivedTopic = c![0].topic;

      bool match = false;
      if (topicPattern.contains('+')) {
        String regexStr = topicPattern.replaceAll('+', '[^/]+');
        if (RegExp('^$regexStr\$').hasMatch(receivedTopic)) {
          match = true;
        }
      } else if (receivedTopic == topicPattern) {
        match = true;
      }

      if (match) {
        final recMess = c[0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        print(
          'MQTT: Received message: topic is $receivedTopic, payload is $pt',
        );
        onMessage(receivedTopic, pt);
      }
    });
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  void disconnect() {
    client?.disconnect();
  }
}
