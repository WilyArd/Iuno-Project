import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class SystemController extends GetxController {
  // [H-1, H-2 FIX] Gunakan secure storage untuk data sensitif
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final providerName = 'OpenRouter'.obs;
  final baseUrl = 'https://openrouter.ai/api/v1'.obs;
  final apiKey = ''.obs;
  final modelName = 'openai/gpt-4o'.obs;

  // New connection protocol and broker customization variables
  final connectionProtocol = 'MQTT'.obs;
  final mqttPreset = 'Docker'.obs;
  final mqttHost = '192.168.10.3'.obs;
  final mqttPort = 1883.obs;
  final mqttWsPort = 9001.obs;
  final mqttUseTls = false.obs;
  final mqttTlsHost = ''.obs;
  final mqttTlsWsUrl = ''.obs;
  final httpTargetUrl = 'http://192.168.10.3'.obs;
  final mqttUsername = ''.obs;
  final mqttPassword = ''.obs;

  // Dynamic device info variables
  final osVersion = 'Loading...'.obs;
  final deviceModel = 'Loading...'.obs;
  final cpuCoreCount = 'Loading...'.obs;
  final dartVersion = 'Loading...'.obs;

  // Language preference: 'en' or 'id'
  final appLanguage = 'en'.obs;

  final isLoading = true.obs;
  final isTestingConnection = false.obs;
  
  final List<String> providers = ['OpenRouter', 'OpenAI', 'Local/Custom'];
  final availableModels = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _loadDynamicDeviceInfo();
    
    // Listen to provider name changes to update default models if we haven't fetched real ones (and API key is not empty)
    ever(providerName, (String newProvider) {
      if (apiKey.value.trim().isEmpty) {
        availableModels.clear();
        modelName.value = '';
      } else if (availableModels.isEmpty || availableModels.length <= 5) {
        _populateDefaultModels(newProvider);
      }
    });

    // Clear models immediately if API Key is cleared
    ever(apiKey, (String key) {
      if (key.trim().isEmpty) {
        availableModels.clear();
        modelName.value = '';
      }
    });

    // Automatically fetch models in the background when API Key changes (debounced by 800ms)
    debounce(apiKey, (String key) {
      final trimmedKey = key.trim();
      if (trimmedKey.isNotEmpty && baseUrl.value.isNotEmpty) {
        testConnection(baseUrl.value, trimmedKey, silent: true);
      }
    }, time: const Duration(milliseconds: 800));

    // Automatically fetch models when provider or base URL changes, if API key is not empty (debounced by 800ms)
    debounce(baseUrl, (String url) {
      final trimmedKey = apiKey.value.trim();
      if (trimmedKey.isNotEmpty && url.isNotEmpty) {
        testConnection(url, trimmedKey, silent: true);
      }
    }, time: const Duration(milliseconds: 800));
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

    // Non-sensitive settings — SharedPreferences OK
    providerName.value = prefs.getString('api_provider_name') ?? 'OpenRouter';
    baseUrl.value = prefs.getString('api_base_url') ?? 'https://openrouter.ai/api/v1';
    connectionProtocol.value = prefs.getString('connection_protocol') ?? 'MQTT';
    mqttPreset.value = prefs.getString('mqtt_preset') ?? 'Docker';
    mqttHost.value = prefs.getString('mqtt_host') ?? '192.168.10.3';
    mqttPort.value = prefs.getInt('mqtt_port') ?? 1883;
    mqttWsPort.value = prefs.getInt('mqtt_websocket_port') ?? 9001;
    mqttUseTls.value = prefs.getBool('mqtt_use_tls') ?? false;
    mqttTlsHost.value = prefs.getString('mqtt_tls_host') ?? '';
    mqttTlsWsUrl.value = prefs.getString('mqtt_tls_websocket_url') ?? '';
    httpTargetUrl.value = prefs.getString('http_target_url') ?? 'http://192.168.10.3';
    appLanguage.value = prefs.getString('app_language') ?? 'en';

    // [H-1, H-2 FIX] Sensitive credentials → FlutterSecureStorage
    apiKey.value = await _secureStorage.read(key: 'api_key') ?? '';
    mqttUsername.value = await _secureStorage.read(key: 'mqtt_username') ?? '';
    mqttPassword.value = await _secureStorage.read(key: 'mqtt_password') ?? '';

    // Handle initial state depending on API key presence
    if (apiKey.value.trim().isEmpty) {
      modelName.value = '';
      availableModels.clear();
    } else {
      modelName.value = prefs.getString('api_model_name') ?? 'openai/gpt-4o';
      _populateDefaultModels(providerName.value);
      if (!availableModels.contains(modelName.value)) {
        availableModels.insert(0, modelName.value);
      }
    }
    
    isLoading.value = false;
  }

  /// Saves the selected language code ('en' or 'id') and applies it immediately.
  Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
    appLanguage.value = langCode;
    final locale = langCode == 'id'
        ? const Locale('id', 'ID')
        : const Locale('en', 'US');
    Get.updateLocale(locale);
    Get.snackbar(
      'language_saved'.tr,
      'language_saved_body'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      colorText: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> saveSettings({
    required String provider,
    required String url,
    required String key,
    required String model,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Non-sensitive → SharedPreferences
    await prefs.setString('api_provider_name', provider);
    await prefs.setString('api_base_url', url);
    await prefs.setString('api_model_name', model);

    // [H-1 FIX] API key → Secure Storage
    await _secureStorage.write(key: 'api_key', value: key);

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

  Future<void> saveBrokerSettings({
    required String protocol,
    required String preset,
    required String host,
    required int port,
    required int wsPort,
    required bool useTls,
    required String tlsHost,
    required String tlsWsUrl,
    required String httpUrl,
    String? username,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Non-sensitive → SharedPreferences
    await prefs.setString('connection_protocol', protocol);
    await prefs.setString('mqtt_preset', preset);
    await prefs.setString('mqtt_host', host);
    await prefs.setInt('mqtt_port', port);
    await prefs.setInt('mqtt_websocket_port', wsPort);
    await prefs.setBool('mqtt_use_tls', useTls);
    await prefs.setString('mqtt_tls_host', tlsHost);
    await prefs.setString('mqtt_tls_websocket_url', tlsWsUrl);
    await prefs.setString('http_target_url', httpUrl);

    // [H-2 FIX] MQTT credentials → Secure Storage
    await _secureStorage.write(key: 'mqtt_username', value: username ?? '');
    await _secureStorage.write(key: 'mqtt_password', value: password ?? '');

    connectionProtocol.value = protocol;
    mqttPreset.value = preset;
    mqttHost.value = host;
    mqttPort.value = port;
    mqttWsPort.value = wsPort;
    mqttUseTls.value = useTls;
    mqttTlsHost.value = tlsHost;
    mqttTlsWsUrl.value = tlsWsUrl;
    httpTargetUrl.value = httpUrl;
    mqttUsername.value = username ?? '';
    mqttPassword.value = password ?? '';

    Get.snackbar(
      'Broker Settings Saved',
      'Connection configuration updated successfully.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      colorText: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> testConnection(String url, String key, {bool silent = false}) async {
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
          if (!silent) {
            Get.snackbar(
              'Connection Successful',
              'Successfully fetched ${availableModels.length} models.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFF00E676),
              colorText: Colors.black,
            );
          }
        } else {
          throw Exception('Invalid response format: missing "data" array');
        }
      } else {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (!silent) {
        Get.snackbar(
          'Connection Failed',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFBA1A1A),
          colorText: Colors.white,
        );
      }
    } finally {
      isTestingConnection.value = false;
    }
  }

  Future<void> _loadDynamicDeviceInfo() async {
    try {
      cpuCoreCount.value = '${Platform.numberOfProcessors} Cores';

      final fullDartVersion = Platform.version;
      final spaceIndex = fullDartVersion.indexOf(' ');
      if (spaceIndex != -1) {
        dartVersion.value = 'v${fullDartVersion.substring(0, spaceIndex)}';
      } else {
        dartVersion.value = 'v$fullDartVersion';
      }

      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final brand = androidInfo.brand;
        final model = androidInfo.model;
        final formattedBrand = brand.isNotEmpty
            ? '${brand[0].toUpperCase()}${brand.substring(1)}'
            : '';
        deviceModel.value = formattedBrand.isNotEmpty && !model.toLowerCase().contains(formattedBrand.toLowerCase())
            ? '$formattedBrand $model'
            : model;
        osVersion.value = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel.value = iosInfo.name;
        osVersion.value = 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceModel.value = linuxInfo.prettyName;
        osVersion.value = 'Linux (${linuxInfo.name} ${linuxInfo.versionId})';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        deviceModel.value = macInfo.model;
        osVersion.value = 'macOS ${macInfo.osRelease}';
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        deviceModel.value = winInfo.computerName;
        osVersion.value = 'Windows ${winInfo.releaseId}';
      } else {
        deviceModel.value = Platform.operatingSystem;
        osVersion.value = Platform.operatingSystemVersion;
      }
    } catch (e) {
      debugPrint('Error loading dynamic device info: $e');
      deviceModel.value = Platform.operatingSystem;
      osVersion.value = Platform.operatingSystemVersion;
    }
  }
}
