import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/dashboard_controller.dart';
import '../models/device_widget_model.dart';

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
                                  ? const Color(0xFFFFE600) // Yellow for connecting
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
            'DEVICES',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),

          // Dynamic Devices
          Obx(() {
            if (controller.devices.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'No devices discovered yet.\nWaiting for MQTT Auto-Discovery...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
              );
            }

            return Wrap(
              spacing: 24,
              runSpacing: 24,
              children: controller.devices.map((device) {
                if (device.type == 'sensor') {
                  return _buildSensorCard(device);
                } else if (device.type == 'switch') {
                  return _buildSwitchCard(device);
                } else if (device.type == 'button') {
                  return _buildButtonCard(device);
                }
                return const SizedBox.shrink();
              }).toList(),
            );
          }),

          const SizedBox(height: 80), // Padding for Bottom Navigation
        ],
      ),
    );
  }

  Widget _buildSensorCard(DeviceWidgetModel device) {
    return _buildBaseCard(
      title: device.name.toUpperCase(),
      icon: Icons.sensors,
      iconColor: const Color(0xFF0040E0),
      accentColor: const Color(0xFF2E5BFF),
      isLightAccent: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Obx(
            () => Text(
              device.value.value == '--' ? '00.0' : device.value.value,
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
              device.unit,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0040E0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard(DeviceWidgetModel device) {
    return _buildBaseCard(
      title: device.name.toUpperCase(),
      icon: Icons.toggle_on,
      iconColor: const Color(0xFFDEC800),
      accentColor: const Color(0xFFFFE600),
      isLightAccent: true,
      child: Obx(() {
        bool isOn = device.value.value.toLowerCase() == 'on';
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isOn ? 'ON' : 'OFF',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: isOn ? const Color(0xFF00E676) : Colors.black54,
              ),
            ),
            Switch(
              value: isOn,
              onChanged: (val) {
                // Optimistic UI update
                device.value.value = val ? 'ON' : 'OFF';
                // Send MQTT command
                controller.sendCommand(device, val ? 'ON' : 'OFF');
              },
              activeColor: Colors.black,
              activeTrackColor: const Color(0xFFFFE600),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[400],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildButtonCard(DeviceWidgetModel device) {
    return _buildBaseCard(
      title: device.name.toUpperCase(),
      icon: Icons.touch_app,
      iconColor: const Color(0xFFBA1A1A),
      accentColor: const Color(0xFFFF4040),
      isLightAccent: false,
      child: GestureDetector(
        onTap: () {
          // Send MQTT command 'PRESS'
          controller.sendCommand(device, 'PRESS');
          
          // Visual feedback
          Get.snackbar(
            'Command Sent',
            '${device.name} pressed.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 1),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'PRESS',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBaseCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color accentColor,
    required bool isLightAccent,
    required Widget child,
  }) {
    return Container(
      // margin: const EdgeInsets.only(bottom: 24),
      width: 300, // Fixed width for wrap layout
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(100),
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
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Content
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
