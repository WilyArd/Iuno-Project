import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/dashboard_controller.dart';
import '../models/device_widget_model.dart';

class DashboardView extends StatelessWidget {
  DashboardView({super.key});

  final DashboardController controller = Get.put(DashboardController());

  // ─── Theming helpers ─────────────────────────────────
  Color _accentColor(DeviceWidgetModel d) {
    final n = d.name.toLowerCase();
    if (n.contains('temp')) return const Color(0xFFFF6B35);
    if (n.contains('hum')) return const Color(0xFF3B82F6);
    if (n.contains('light')) return const Color(0xFFF59E0B);
    if (n.contains('pressure')) return const Color(0xFF8B5CF6);
    return const Color(0xFF10B981);
  }

  Color _cardBg(DeviceWidgetModel d) {
    final n = d.name.toLowerCase();
    if (n.contains('temp')) return const Color(0xFFFFF4EF);
    if (n.contains('hum')) return const Color(0xFFEFF6FF);
    if (n.contains('light')) return const Color(0xFFFFFBEB);
    if (n.contains('pressure')) return const Color(0xFFF5F3FF);
    return const Color(0xFFECFDF5);
  }

  IconData _icon(DeviceWidgetModel d) {
    final n = d.name.toLowerCase();
    if (n.contains('temp')) return Icons.thermostat_rounded;
    if (n.contains('hum')) return Icons.water_drop_rounded;
    if (n.contains('light')) return Icons.wb_sunny_rounded;
    if (n.contains('pressure')) return Icons.compress_rounded;
    return Icons.sensors_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: RefreshIndicator(
        color: Colors.black,
        onRefresh: () async {
          if (!controller.isBrokerConnected.value) {
            await controller.toggleConnection();
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHubCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildDeviceSliver(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ─── Hub status card ────────────────────────────────
  Widget _buildHubCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon column
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.hub_rounded, color: Color(0xFF333333), size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Main Hub',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Obx(() {
                  final count = controller.devices.length;
                  return Text(
                    count == 0 ? 'Scanning for devices…' : '$count device(s) found',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: const Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }),
              ],
            ),
          ),
          Obx(() => _buildStatusPill()),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    final connecting = controller.isConnecting.value;
    final deviceLive = controller.isDeviceConnected.value;
    final brokerOk = controller.isBrokerConnected.value;

    Color bg, fg;
    String label;
    IconData dot;

    if (connecting) {
      bg = const Color(0xFFFFF9C4); fg = const Color(0xFF9A7700); label = 'Connecting'; dot = Icons.sync_rounded;
    } else if (deviceLive) {
      bg = const Color(0xFFD1FAE5); fg = const Color(0xFF065F46); label = 'Live'; dot = Icons.circle;
    } else if (brokerOk) {
      bg = const Color(0xFFFFF3CD); fg = const Color(0xFF8A5700); label = 'Broker OK'; dot = Icons.circle;
    } else {
      bg = const Color(0xFFFFE4E4); fg = const Color(0xFF991B1B); label = 'Offline'; dot = Icons.circle;
    }

    return GestureDetector(
      onTap: controller.toggleConnection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(dot, color: fg, size: 8),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section header ─────────────────────────────────
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Devices',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          Obx(() => Text(
                '${controller.devices.length} total',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: const Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              )),
        ],
      ),
    );
  }

  // ─── Sliver device grid ─────────────────────────────
  Widget _buildDeviceSliver() {
    return Obx(() {
      if (controller.devices.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildEmptyState(),
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final d = controller.devices[i];
              if (d.type == 'sensor') return _buildSensorCard(d);
              if (d.type == 'switch') return _buildSwitchCard(d);
              if (d.type == 'button') return _buildButtonCard(d);
              return const SizedBox.shrink();
            },
            childCount: controller.devices.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
        ),
      );
    });
  }

  // ─── Empty state ────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.radar_rounded, size: 36, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 18),
          Text(
            'Scanning…',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Waiting for MQTT Auto-Discovery.\nMake sure your ESP32 is powered on.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: const Color(0xFF999999),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sensor card ────────────────────────────────────
  Widget _buildSensorCard(DeviceWidgetModel device) {
    final accent = _accentColor(device);
    final bg = _cardBg(device);
    final icon = _icon(device);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: controller.isDeviceConnected.value
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        controller.isDeviceConnected.value ? 'Live' : 'Wait',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: controller.isDeviceConnected.value
                              ? const Color(0xFF065F46)
                              : const Color(0xFF888888),
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              device.name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF777777),
              ),
            ),
            const Spacer(),
            // Value
            Obx(() {
              final raw = device.value.value;
              final noData = raw == '--';
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    noData ? '--' : raw,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: noData ? const Color(0xFFCCCCCC) : Colors.black,
                      letterSpacing: -1.5,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5, left: 3),
                    child: Text(
                      device.unit,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 10),
            // Sparkline
            Obx(() {
              final spots = device.history.toList();
              if (spots.length < 2) {
                return SizedBox(
                  height: 32,
                  child: Center(
                    child: Text(
                      'Collecting…',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        color: const Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 32,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: accent,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: accent.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Switch card ────────────────────────────────────
  Widget _buildSwitchCard(DeviceWidgetModel device) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.toggle_on_rounded,
                      color: Color(0xFFF59E0B), size: 22),
                ),
                Obx(() {
                  final isOn = device.value.value.toLowerCase() == 'on';
                  return Switch.adaptive(
                    value: isOn,
                    activeThumbColor: Colors.black,
                    activeTrackColor: const Color(0xFFFFE600),
                    onChanged: (val) {
                      device.value.value = val ? 'ON' : 'OFF';
                      controller.sendCommand(device, val ? 'ON' : 'OFF');
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              device.name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF777777),
              ),
            ),
            const Spacer(),
            Obx(() {
              final isOn = device.value.value.toLowerCase() == 'on';
              return Text(
                isOn ? 'ON' : 'OFF',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: isOn ? const Color(0xFF111111) : const Color(0xFFDDDDDD),
                  letterSpacing: -1,
                  height: 1,
                ),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ─── Button card ────────────────────────────────────
  Widget _buildButtonCard(DeviceWidgetModel device) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.touch_app_rounded, color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              device.name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF777777),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                controller.sendCommand(device, 'PRESS');
                Get.snackbar(
                  '',
                  '${device.name} triggered.',
                  titleText: const SizedBox.shrink(),
                  messageText: Text(
                    '${device.name} triggered.',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
                  ),
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.black,
                  colorText: Colors.white,
                  borderRadius: 14,
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Press',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
