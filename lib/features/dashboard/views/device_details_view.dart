import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/dashboard_controller.dart';
import '../models/device_widget_model.dart';

class DeviceDetailsView extends StatelessWidget {
  final String groupName;
  final DashboardController controller = Get.find<DashboardController>();
  final RxString rxGroupName;

  DeviceDetailsView({super.key, required this.groupName})
      : rxGroupName = groupName.obs;

  // ─── Theming helpers ─────────────────────────────────
  Color _accentColor(DeviceWidgetModel d) {
    final n = d.name.toLowerCase();
    if (n.contains('temp') || n.contains('suhu')) return const Color(0xFFFF6B35);
    if (n.contains('hum') || n.contains('kelembaban') && !n.contains('tanah')) return const Color(0xFF0284C7);
    if (n.contains('light') || n.contains('ldr') || n.contains('cahaya')) return const Color(0xFFF59E0B);
    if (n.contains('dist') || n.contains('jarak')) return const Color(0xFF0D9488);
    if (n.contains('soil') || n.contains('tanah')) return const Color(0xFF8B5CF6);
    if (n.contains('pressure') || n.contains('tekanan') || n.contains('press')) return const Color(0xFF6366F1);
    return const Color(0xFF10B981);
  }

  Color _cardBg(DeviceWidgetModel d) {
    final n = d.name.toLowerCase();
    if (n.contains('temp') || n.contains('suhu')) return const Color(0xFFFFF4EF);
    if (n.contains('hum') || n.contains('kelembaban') && !n.contains('tanah')) return const Color(0xFFF0F9FF);
    if (n.contains('light') || n.contains('ldr') || n.contains('cahaya')) return const Color(0xFFFFFBEB);
    if (n.contains('dist') || n.contains('jarak')) return const Color(0xFFF0FDFA);
    if (n.contains('soil') || n.contains('tanah')) return const Color(0xFFF5F3FF);
    if (n.contains('pressure') || n.contains('tekanan') || n.contains('press')) return const Color(0xFFEEF2FF);
    return const Color(0xFFECFDF5);
  }

  IconData _icon(DeviceWidgetModel d) {
    final n = d.name.toLowerCase();
    if (n.contains('temp') || n.contains('suhu')) return Icons.thermostat_rounded;
    if (n.contains('hum') || n.contains('kelembaban') && !n.contains('tanah')) return Icons.water_drop_rounded;
    if (n.contains('light') || n.contains('ldr') || n.contains('cahaya')) return Icons.wb_sunny_rounded;
    if (n.contains('dist') || n.contains('jarak')) return Icons.straighten_rounded;
    if (n.contains('soil') || n.contains('tanah')) return Icons.grass_rounded;
    if (n.contains('pressure') || n.contains('tekanan') || n.contains('press')) return Icons.compress_rounded;
    return Icons.sensors_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
          rxGroupName.value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
            fontSize: 18,
          ),
        )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF0F172A), size: 20),
            onPressed: () => _showRenameGroupDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF0F172A), size: 24),
            onPressed: () => _showAddDeviceSheet(context),
          ),
        ],
      ),
      body: Obx(() {
        final activeGroup = rxGroupName.value;
        // Filter widgets belonging to this group
        final groupWidgets = controller.devices.where((d) => d.deviceGroup == activeGroup).toList();
        
        if (groupWidgets.isEmpty) {
          return Center(
            child: Text(
              'No widgets in this device.',
              style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8)),
            ),
          );
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            children: [
              _buildDeviceStatusBanner(),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupWidgets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.76,
                ),
                itemBuilder: (ctx, i) {
                  final d = groupWidgets[i];
                  final Widget card;
                  if (d.type == 'sensor') {
                    card = _buildSensorCard(d);
                  } else if (d.type == 'switch') {
                    card = _buildSwitchCard(d);
                  } else if (d.type == 'button') {
                    card = _buildButtonCard(d);
                  } else {
                    card = const SizedBox.shrink();
                  }
                  
                  return GestureDetector(
                    onLongPress: () => _showManageDeviceDialog(ctx, d),
                    child: card,
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDeviceStatusBanner() {
    return Obx(() {
      final isDemo = controller.isDemoMode.value;
      final isConnected = controller.isDeviceConnected.value;
      
      final String statusLabel = isDemo ? 'Simulated Connection Active' : (isConnected ? 'Device Online' : 'Device Offline');
      final Color statusBg = isDemo 
          ? const Color(0xFF0D9488)
          : (isConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444));

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: statusBg.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: statusBg.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(
              isDemo ? Icons.bolt_rounded : (isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded),
              color: statusBg,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              statusLabel,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: statusBg,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ─── Inline telemetry meters ─────────────────────────
  Widget _buildInlineMeter(DeviceWidgetModel device, Color accent) {
    return Obx(() {
      final raw = device.value.value;
      if (raw == '--') return const SizedBox.shrink();
      
      final name = device.name.toLowerCase();
      double percent = 0.0;
      String label = '';
      
      if (name.contains('temp') || name.contains('suhu')) {
        final val = double.tryParse(raw) ?? 0.0;
        percent = ((val - 15.0) / 25.0).clamp(0.0, 1.0);
        label = '${(percent * 100).toInt()}% Thermal';
      } else if (name.contains('hum') || name.contains('kelembaban') && !name.contains('tanah')) {
        final val = double.tryParse(raw) ?? 0.0;
        percent = (val / 100.0).clamp(0.0, 1.0);
        label = '${val.toInt()}% Air RH';
      } else if (name.contains('dist') || name.contains('jarak')) {
        final val = double.tryParse(raw) ?? 0.0;
        percent = (val / 80.0).clamp(0.0, 1.0);
        label = val < 15.0 ? '🚨 DEKAT (${val.toInt()}cm)' : 'AMAN (${val.toInt()}cm)';
      } else if (name.contains('light') || name.contains('cahaya')) {
        final val = double.tryParse(raw) ?? 0.0;
        percent = (val / 900.0).clamp(0.0, 1.0);
        label = '${val.toInt()} Lux';
      } else if (name.contains('soil') || name.contains('tanah')) {
        final val = double.tryParse(raw) ?? 0.0;
        percent = (val / 100.0).clamp(0.0, 1.0);
        label = '${val.toInt()}% Soil Moisture';
      } else if (name.contains('press') || name.contains('tekanan')) {
        final val = double.tryParse(raw) ?? 0.0;
        percent = ((val - 990.0) / 35.0).clamp(0.0, 1.0);
        label = '${val.toInt()} hPa';
      } else {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      );
    });
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 20),
                ),
                Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: controller.isDeviceConnected.value
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        controller.isDeviceConnected.value ? 'Live' : 'Wait',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: controller.isDeviceConnected.value
                              ? const Color(0xFF065F46)
                              : const Color(0xFF888888),
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              device.name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            Obx(() {
              final raw = device.value.value;
              final noData = raw == '--';
              if (noData) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.signal_cellular_nodata_rounded,
                            size: 18, color: accent.withValues(alpha: 0.35)),
                        const SizedBox(width: 6),
                        Text(
                          'Waiting…',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'No signal yet',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        color: const Color(0xFFE2E8F0),
                        fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    raw,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -1.5,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      device.unit,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 10),
            _buildInlineMeter(device, accent),
            const SizedBox(height: 10),
            Obx(() {
              final spots = device.history.toList();
              if (spots.length < 2) {
                return SizedBox(
                  height: 28,
                  child: Center(
                    child: Text(
                      'Stream loading…',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 28,
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
                          color: accent.withValues(alpha: 0.08),
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
    return Obx(() {
      final isOn = device.value.value.toLowerCase() == 'on';
      final accent = const Color(0xFF0D9488);
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOn ? accent.withValues(alpha: 0.4) : const Color(0xFFF1F5F9),
            width: isOn ? 2.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isOn 
                  ? accent.withValues(alpha: 0.12) 
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isOn ? 20 : 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isOn ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isOn ? Icons.power_rounded : Icons.power_off_rounded,
                      color: isOn ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                  Switch.adaptive(
                    value: isOn,
                    activeThumbColor: Colors.white,
                    activeTrackColor: accent,
                    onChanged: (val) {
                      controller.toggleSwitch(device, val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                device.name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Text(
                isOn ? 'ON' : 'OFF',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: isOn ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    });
  }

  // ─── Button card ────────────────────────────────────
  Widget _buildButtonCard(DeviceWidgetModel device) {
    final rxPressed = false.obs;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.touch_app_rounded, color: Color(0xFFF43F5E), size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              device.name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            Obx(() {
              final pressed = rxPressed.value;
              return AnimatedScale(
                scale: pressed ? 0.94 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: GestureDetector(
                  onTapDown: (_) => rxPressed.value = true,
                  onTapUp: (_) => rxPressed.value = false,
                  onTapCancel: () => rxPressed.value = false,
                  onTap: () {
                    controller.sendCommand(device, 'PRESS');
                    Get.snackbar(
                      '',
                      '${device.name} triggered.',
                      titleText: const SizedBox.shrink(),
                      messageText: Text(
                        '${device.name} triggered successfully.',
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
                      ),
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black,
                      colorText: Colors.white,
                      borderRadius: 14,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 1),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'PRESS',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // ─── Manage Widget Dialog ─────────────────────────────
  void _showManageDeviceDialog(BuildContext context, DeviceWidgetModel device) {
    final renameController = TextEditingController(text: device.name);
    final groupController = TextEditingController(text: device.deviceGroup);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            'Manage Widget',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DEVICE / GROUP NAME',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: groupController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                  ),
                ),
                style: GoogleFonts.spaceGrotesk(fontSize: 14, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              
              Text(
                'WIDGET NAME',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: renameController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                  ),
                ),
                style: GoogleFonts.spaceGrotesk(fontSize: 14, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${device.id}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      controller.deleteDevice(device.id);
                      Navigator.pop(ctx);
                      Get.snackbar(
                        'Deleted',
                        '${device.name} removed from dashboard.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        borderRadius: 14,
                        margin: const EdgeInsets.all(16),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final newName = renameController.text.trim();
                      final newGroup = groupController.text.trim();
                      if (newName.isEmpty) return;
                      controller.renameDevice(device.id, newName, newGroup);
                      Navigator.pop(ctx);
                      Get.snackbar(
                        'Success',
                        'Widget renamed to $newName.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF0D9488),
                        colorText: Colors.white,
                        borderRadius: 14,
                        margin: const EdgeInsets.all(16),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ─── Add Custom Device Bottom Sheet ───────────────────
  void _showAddDeviceSheet(BuildContext context) {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final stateTopicController = TextEditingController();
    final commandTopicController = TextEditingController();
    final groupController = TextEditingController(text: rxGroupName.value);
    
    final selectedType = 'sensor'.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add IoT Widget',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Text(
                  'WIDGET TYPE',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() => Row(
                  children: [
                    _buildTypeChip('sensor', 'Sensor', Icons.sensors_rounded, selectedType),
                    const SizedBox(width: 8),
                    _buildTypeChip('switch', 'Switch', Icons.power_rounded, selectedType),
                    const SizedBox(width: 8),
                    _buildTypeChip('button', 'Button', Icons.touch_app_rounded, selectedType),
                  ],
                )),
                const SizedBox(height: 20),
                
                _buildTextField(
                  controller: groupController,
                  label: 'DEVICE / GROUP NAME',
                  hint: 'e.g. ESP32 Utama, Node Dapur',
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: nameController,
                  label: 'WIDGET NAME',
                  hint: 'e.g. Suhu Kamar, Relay Lampu',
                ),
                const SizedBox(height: 16),
                
                Obx(() {
                  if (selectedType.value == 'sensor') {
                    return Column(
                      children: [
                        _buildTextField(
                          controller: unitController,
                          label: 'UNIT OF MEASUREMENT',
                          hint: 'e.g. °C, %, cm, lx',
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                
                _buildTextField(
                  controller: stateTopicController,
                  label: 'MQTT STATE TOPIC',
                  hint: 'e.g. iuno/sensor/temp',
                ),
                const SizedBox(height: 16),
                
                Obx(() {
                  if (selectedType.value != 'sensor') {
                    return Column(
                      children: [
                        _buildTextField(
                          controller: commandTopicController,
                          label: 'MQTT COMMAND TOPIC',
                          hint: 'e.g. iuno/relay/cmd',
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                
                const SizedBox(height: 12),
                
                GestureDetector(
                  onTap: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      Get.snackbar(
                        'Error',
                        'Device name cannot be empty.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        borderRadius: 14,
                        margin: const EdgeInsets.all(16),
                      );
                      return;
                    }
                    
                    controller.addCustomDevice(
                      name: name,
                      type: selectedType.value,
                      unit: selectedType.value == 'sensor' ? unitController.text.trim() : '',
                      stateTopic: stateTopicController.text.trim(),
                      commandTopic: commandTopicController.text.trim(),
                      deviceGroup: groupController.text.trim(),
                    );
                    
                    Navigator.pop(ctx);
                    Get.snackbar(
                      'Success',
                      '$name added successfully.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFF0D9488),
                      colorText: Colors.white,
                      borderRadius: 14,
                      margin: const EdgeInsets.all(16),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF0EA5E9)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Create Widget',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, RxString selectedType) {
    final isSelected = selectedType.value == type;
    final accent = const Color(0xFF0D9488);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => selectedType.value = type,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
            border: Border.all(
              color: isSelected ? accent : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? accent : const Color(0xFF64748B),
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? accent : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
            ),
          ),
          style: GoogleFonts.spaceGrotesk(fontSize: 14, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }

  // ─── Rename Device Group Dialog ──────────────────────
  void _showRenameGroupDialog(BuildContext context) {
    final renameController = TextEditingController(text: rxGroupName.value);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Text(
            'Rename Device',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEW DEVICE NAME',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: renameController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                  ),
                ),
                style: GoogleFonts.spaceGrotesk(fontSize: 14, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Batal',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = renameController.text.trim();
                if (newName.isNotEmpty) {
                  controller.renameDeviceGroup(rxGroupName.value, newName);
                  rxGroupName.value = newName;
                  Navigator.pop(ctx);
                  Get.snackbar(
                    'Sukses',
                    'Device berhasil diubah namanya menjadi $newName.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF0D9488),
                    colorText: Colors.white,
                    borderRadius: 14,
                    margin: const EdgeInsets.all(16),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Simpan',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}
