import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/dashboard_controller.dart';
import '../models/device_widget_model.dart';
import 'device_details_view.dart';

class DashboardView extends StatelessWidget {
  DashboardView({super.key});

  final DashboardController controller = Get.put(DashboardController());

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
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHubCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context),
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.router_rounded, color: Color(0xFF0EA5E9), size: 26),
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
                  final isConnected = controller.isBrokerConnected.value;
                  if (!isConnected) {
                    return Text(
                      'Broker Disconnected',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: const Color(0xFFEF4444),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }
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
  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Devices',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ],
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

      // Group devices by physical device name (deviceGroup)
      final Map<String, List<DeviceWidgetModel>> grouped = {};
      for (var d in controller.devices) {
        grouped.putIfAbsent(d.deviceGroup, () => []).add(d);
      }

      final keys = grouped.keys.toList();

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final groupName = keys[index];
              final groupWidgets = grouped[groupName]!;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => Get.to(() => DeviceDetailsView(groupName: groupName)),
                  onLongPress: () => _showRenameGroupDialog(context, groupName),
                  behavior: HitTestBehavior.opaque,
                  child: _buildDeviceGroupCard(groupName, groupWidgets.length),
                ),
              );
            },
            childCount: keys.length,
          ),
        ),
      );
    });
  }

  Widget _buildDeviceGroupCard(String groupName, int widgetCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.developer_board_rounded,
              color: Color(0xFF0F172A),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$widgetCount widget(s) active',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final isDemo = controller.isDemoMode.value;
            final isConnected = controller.isDeviceConnected.value;
            
            final String statusLabel = isDemo ? 'Simulated' : (isConnected ? 'Active' : 'Offline');
            final Color statusBg = isDemo 
                ? const Color(0xFF0D9488).withValues(alpha: 0.1)
                : (isConnected ? const Color(0xFF22C55E).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1));
            final Color statusText = isDemo 
                ? const Color(0xFF0D9488)
                : (isConnected ? const Color(0xFF22C55E) : const Color(0xFFEF4444));

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusText.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusText,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 14,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────
  Widget _buildEmptyState() {
    return Obx(() {
      final isConnected = controller.isBrokerConnected.value;

      if (!isConnected) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
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
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.cloud_off_rounded, size: 36, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 18),
              Text(
                'Offline',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'MQTT Broker is disconnected. Tap the status badge above or configure settings to connect and discover devices.',
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

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
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
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.radar_rounded, size: 36, color: Color(0xFF0EA5E9)),
            ),
            const SizedBox(height: 18),
            Text(
              'Scanning for nodes…',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Listening for MQTT Auto-Discovery signals.\nMake sure your ESP32 node is powered on.',
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
    });
  }

  // ─── Rename Device Group Dialog ──────────────────────
  void _showRenameGroupDialog(BuildContext context, String currentName) {
    final renameController = TextEditingController(text: currentName);
    
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
                  controller.renameDeviceGroup(currentName, newName);
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
