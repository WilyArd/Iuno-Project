import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'features/splash/views/splash_view.dart';

void main() {
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
