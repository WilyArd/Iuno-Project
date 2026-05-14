import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SystemController extends GetxController {
  final providerName = 'OpenRouter'.obs;
  final baseUrl = 'https://openrouter.ai/api/v1'.obs;
  final apiKey = ''.obs;
  final modelName = 'openai/gpt-4o'.obs;

  final isLoading = true.obs;
  final isTestingConnection = false.obs;
  
  final List<String> providers = ['OpenRouter', 'OpenAI', 'Local/Custom'];
  final availableModels = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    
    // Listen to provider name changes to update default models if we haven't fetched real ones
    ever(providerName, (String newProvider) {
      if (availableModels.isEmpty || availableModels.length <= 5) {
        _populateDefaultModels(newProvider);
      }
    });
  }

  void _populateDefaultModels(String provider) {
    if (provider == 'OpenRouter') {
      availableModels.value = [
        'openai/gpt-4o',
        'openai/gpt-4o-mini',
        'anthropic/claude-3-opus',
        'anthropic/claude-3.5-sonnet',
        'google/gemini-pro-1.5',
        'meta-llama/llama-3-8b-instruct',
      ];
    } else if (provider == 'OpenAI') {
      availableModels.value = [
        'gpt-4o',
        'gpt-4-turbo',
        'gpt-3.5-turbo',
      ];
    } else {
      availableModels.value = ['custom-model'];
    }
  }

  Future<void> _loadSettings() async {
    isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();
    providerName.value = prefs.getString('api_provider_name') ?? 'OpenRouter';
    baseUrl.value = prefs.getString('api_base_url') ?? 'https://openrouter.ai/api/v1';
    apiKey.value = prefs.getString('api_key') ?? '';
    modelName.value = prefs.getString('api_model_name') ?? 'openai/gpt-4o';
    
    _populateDefaultModels(providerName.value);
    if (!availableModels.contains(modelName.value)) {
      availableModels.insert(0, modelName.value);
    }
    
    isLoading.value = false;
  }

  Future<void> saveSettings({
    required String provider,
    required String url,
    required String key,
    required String model,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('api_provider_name', provider);
    await prefs.setString('api_base_url', url);
    await prefs.setString('api_key', key);
    await prefs.setString('api_model_name', model);

    providerName.value = provider;
    baseUrl.value = url;
    apiKey.value = key;
    modelName.value = model;

    Get.snackbar(
      'Settings Saved',
      'API Configuration updated successfully.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> testConnection(String url, String key) async {
    isTestingConnection.value = true;
    try {
      final uri = Uri.parse('$url/models');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $key',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'] is List) {
          availableModels.clear();
          for (var model in data['data']) {
            if (model['id'] != null) {
              availableModels.add(model['id'].toString());
            }
          }
          if (availableModels.isNotEmpty && !availableModels.contains(modelName.value)) {
            modelName.value = availableModels.first;
          }
          Get.snackbar(
            'Connection Successful',
            'Successfully fetched ${availableModels.length} models.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF00E676),
            colorText: Colors.black,
          );
        } else {
          throw Exception('Invalid response format: missing "data" array');
        }
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar(
        'Connection Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFBA1A1A),
        colorText: Colors.white,
      );
    } finally {
      isTestingConnection.value = false;
    }
  }
}
