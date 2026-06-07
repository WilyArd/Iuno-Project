import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/splash/views/splash_view.dart';
import 'core/l10n/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize port for communication between TaskHandler and UI isolate
  FlutterForegroundTask.initCommunicationPort();

  // Load saved locale preference before running the app
  final prefs = await SharedPreferences.getInstance();
  final langCode = prefs.getString('app_language') ?? 'en';
  final locale = langCode == 'id' ? const Locale('id', 'ID') : const Locale('en', 'US');

  runApp(MainApp(initialLocale: locale));
}

class MainApp extends StatelessWidget {
  final Locale initialLocale;
  const MainApp({super.key, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'IUNO IoT',
      debugShowCheckedModeBanner: false,

      // ── Localization ───────────────────────────────────────────
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFE600)),
        useMaterial3: true,
      ),
      home: SplashView(),
    );
  }
}
