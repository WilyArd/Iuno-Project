import 'package:get/get.dart';
import '../../../core/layouts/main_layout.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToHome();
  }

  void _navigateToHome() async {
    // Memberikan waktu agar animasi logo bisa terlihat oleh user (dipercepat)
    await Future.delayed(const Duration(milliseconds: 1500));
    Get.offAll(
      () => MainLayout(),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 800),
    );
  }
}
