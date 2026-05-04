import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends StatelessWidget {
  DashboardView({super.key});

  // Inject controller
  final DashboardController controller = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            margin: const EdgeInsets.only(bottom: 32),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Main Hub',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Obx(
                  () => GestureDetector(
                    onTap: controller.toggleConnection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: controller.isConnecting.value
                            ? Colors.grey[200]
                            : Colors.white,
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: controller.isConnecting.value
                                  ? const Color(
                                      0xFFFFE600,
                                    ) // Yellow for connecting
                                  : (controller.isDeviceConnected.value
                                        ? const Color(0xFF00E676)
                                        : const Color(0xFFBA1A1A)),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            controller.isConnecting.value
                                ? 'CONNECTING...'
                                : (controller.isDeviceConnected.value
                                      ? 'CONNECTED'
                                      : 'DISCONNECTED'),
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Text(
            'DATA SENSOR',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Suhu Card
          _buildNeubrutalCard(
            title: 'SUHU',
            rxValue: controller.temperature,
            targetValue: controller.targetTemperature,
            unit: '°C',
            icon: Icons.thermostat,
            iconColor: const Color(0xFFDEC800), // Darker yellow for text
            accentColor: const Color(0xFFFFE600), // Primary container yellow
          ),

          // Kelembaban Card
          _buildNeubrutalCard(
            title: 'KELEMBABAN',
            rxValue: controller.humidity,
            targetValue: controller.targetHumidity,
            unit: '%',
            icon: Icons.water_drop,
            iconColor: const Color(0xFF0040E0), // Secondary blue
            accentColor: const Color(0xFF2E5BFF), // Secondary container
            isLightAccent: false,
          ),

          const SizedBox(height: 80), // Padding for Bottom Navigation
        ],
      ),
    );
  }

  Widget _buildNeubrutalCard({
    required String title,
    required RxString rxValue,
    required RxDouble targetValue,
    required String unit,
    required IconData icon,
    required Color iconColor,
    required Color accentColor,
    bool isLightAccent = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Top right decoration
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(120),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black, width: 3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: iconColor, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Text(
                          'LIVE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isLightAccent ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Value
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(
                          () => Text(
                            rxValue.value == '--' ? '00.0' : rxValue.value,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            unit,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Obx(
                          () => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFBA1A1A),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'AI TARGET: ${targetValue.value.toStringAsFixed(0)}$unit',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFBA1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() {
                          if (rxValue.value == '--') {
                            return const SizedBox(
                              height: 16,
                            ); // Reserve space when disconnected
                          }

                          double current =
                              double.tryParse(rxValue.value) ?? 0.0;
                          double diff = current - targetValue.value;
                          bool isUp = diff >= 0;
                          Color varianceColor = isUp
                              ? const Color(0xFFBA1A1A)
                              : const Color(0xFF00E676);
                          IconData varianceIcon = isUp
                              ? Icons.arrow_upward
                              : Icons.arrow_downward;
                          String sign = isUp ? '+' : '';

                          return Row(
                            children: [
                              Icon(
                                varianceIcon,
                                color: varianceColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$sign${diff.toStringAsFixed(2)}$unit',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: varianceColor,
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
