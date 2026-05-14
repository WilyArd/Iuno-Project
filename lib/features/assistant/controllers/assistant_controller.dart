import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../system/controllers/system_controller.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

class AssistantController extends GetxController {
  var messages = <ChatMessage>[].obs;
  var isTyping = false.obs;

  final DashboardController _dashboardController =
      Get.find<DashboardController>();
  final SystemController _systemController = Get.find<SystemController>();

  @override
  void onInit() {
    super.onInit();
    messages.add(ChatMessage(
        "Hello! I am your IUNO AI Assistant. I'm connected to your configured AI provider. How can I help you manage your devices today?",
        false));

    // Still listen for MQTT replies (from ESP-Claw hardware if present)
    ever(_dashboardController.isBrokerConnected, (bool connected) {
      if (connected) {
        _dashboardController.mqttService.subscribe('iuno/ai/reply',
            (topic, msg) {
          if (msg.isNotEmpty) {
            messages.add(ChatMessage(msg.trim(), false));
            isTyping.value = false;
          }
        });
      }
    });
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    messages.add(ChatMessage(text.trim(), true));
    isTyping.value = true;

    // Also publish to MQTT for any hardware listening
    if (_dashboardController.isBrokerConnected.value) {
      _dashboardController.mqttService.publish('iuno/ai/request', text.trim());
    }

    final apiKey = _systemController.apiKey.value;
    final baseUrl = _systemController.baseUrl.value;
    final model = _systemController.modelName.value;

    if (apiKey.isNotEmpty && baseUrl.isNotEmpty && model.isNotEmpty) {
      _callAiApi(text.trim(), baseUrl, apiKey, model);
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        messages.add(ChatMessage(
            "⚠️ API belum dikonfigurasi. Silakan masuk ke tab SYSTEM, isi API Key dan klik Save Configuration.",
            false));
        isTyping.value = false;
      });
    }
  }

  Future<void> _callAiApi(
      String userMessage, String baseUrl, String apiKey, String model) async {
    try {
      // Build context from device states
      final deviceContext = _buildDeviceContext();

      final uri = Uri.parse('$baseUrl/chat/completions');
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://iuno-iot.app',
              'X-Title': 'IUNO IoT Assistant',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are IUNO AI Assistant, an intelligent IoT device manager. '
                          'You help users monitor and control their ESP32/ESP-Claw devices via MQTT. '
                          'Current device states:\n$deviceContext\n'
                          'Be concise and helpful. Respond in the same language as the user.'
                },
                {'role': 'user', 'content': userMessage},
              ],
              'max_tokens': 512,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['choices']?[0]?['message']?['content']?.toString().trim();
        if (reply != null && reply.isNotEmpty) {
          messages.add(ChatMessage(reply, false));
        } else {
          messages.add(ChatMessage('(Respon kosong dari AI)', false));
        }
      } else {
        final err = jsonDecode(response.body);
        final errMsg =
            err['error']?['message'] ?? 'Status ${response.statusCode}';
        messages.add(ChatMessage('❌ API Error: $errMsg', false));
      }
    } catch (e) {
      messages.add(ChatMessage('❌ Gagal menghubungi API: $e', false));
      Get.snackbar(
        'AI API Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFBA1A1A),
        colorText: Colors.white,
      );
    } finally {
      isTyping.value = false;
    }
  }

  String _buildDeviceContext() {
    final devices = _dashboardController.devices;
    if (devices.isEmpty) return 'No devices connected.';
    return devices
        .map((d) =>
            '- ${d.name} (${d.type}): ${d.value.value} ${d.unit}')
        .join('\n');
  }
}
