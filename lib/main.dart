import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'features/splash/views/splash_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize port for communication between TaskHandler and UI isolate
  FlutterForegroundTask.initCommunicationPort();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan GetMaterialApp agar fitur GetX bisa dipakai sepenuhnya
    return GetMaterialApp(
      title: 'IUNO IoT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFE600)),
        useMaterial3: true,
      ),
      home: SplashView(),
    );
  }
}
