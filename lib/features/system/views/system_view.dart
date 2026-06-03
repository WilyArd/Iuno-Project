import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/system_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class SystemView extends StatelessWidget {
  final SystemController controller = Get.find<SystemController>();
  final RxString _expandedTile = ''.obs;

  final baseUrlController = TextEditingController();
  final apiKeyController = TextEditingController();
  final modelController = TextEditingController();

  // Broker connection controllers
  final mqttHostController = TextEditingController();
  final mqttPortController = TextEditingController();
  final httpUrlController = TextEditingController();
  final mqttUsernameController = TextEditingController();
  final mqttPasswordController = TextEditingController();

  void _syncControllers() {
    baseUrlController.text = controller.baseUrl.value;
    apiKeyController.text = controller.apiKey.value;
    modelController.text = controller.modelName.value;
    mqttHostController.text = controller.mqttHost.value.isNotEmpty
        ? controller.mqttHost.value
        : controller.mqttTlsHost.value;
    mqttPortController.text = controller.mqttPort.value.toString();
    httpUrlController.text = controller.httpTargetUrl.value;
    mqttUsernameController.text = controller.mqttUsername.value;
    mqttPasswordController.text = controller.mqttPassword.value;
  }

  SystemView({super.key}) {
    ever(controller.isLoading, (isLoading) {
      if (!isLoading) _syncControllers();
    });
    ever(controller.modelName, (model) {
      if (modelController.text != model) modelController.text = model;
    });
    if (!controller.isLoading.value) _syncControllers();
  }

  void _toggleTile(String tile) {
    if (_expandedTile.value == tile) {
      _expandedTile.value = '';
    } else {
      _expandedTile.value = tile;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
    final dash = Get.find<DashboardController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Premium gradient header ──
            _buildHeroHeader(dash),

            // ── Setting Cards ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Obx(() {
                final expanded = _expandedTile.value;
                final brokerOk = dash.isBrokerConnected.value;
                final deviceLive = dash.isDeviceConnected.value;
                final savedHost = controller.mqttTlsHost.value.isNotEmpty
                    ? controller.mqttTlsHost.value
                    : (controller.mqttHost.value.isNotEmpty
                        ? controller.mqttHost.value
                        : 'Not configured');
                final String brokerStatus = dash.isConnecting.value
                    ? 'Connecting\u2026'
                    : deviceLive
                        ? 'Live'
                        : (brokerOk ? 'Broker OK' : 'Offline');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Connection'),
                    _buildSettingTile(
                      icon: Icons.router_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      title: 'MQTT Broker',
                      subtitle: '$savedHost  ·  $brokerStatus',
                      statusDot: brokerOk ? const Color(0xFF22C55E) : (dash.isConnecting.value ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                      isExpanded: expanded == 'Broker',
                      onTap: () => _toggleTile('Broker'),
                      child: _buildBrokerCardContent(dash),
                    ),
                    _buildSettingTile(
                      icon: Icons.science_rounded,
                      iconColor: const Color(0xFF0D9488),
                      title: 'Demo Mode',
                      subtitle: dash.isDemoMode.value ? 'Simulated data active' : 'Real MQTT data',
                      statusDot: dash.isDemoMode.value ? const Color(0xFF0D9488) : null,
                      isExpanded: expanded == 'Simulation',
                      onTap: () => _toggleTile('Simulation'),
                      child: _buildSimulationContent(dash),
                    ),
                    _buildSectionHeader('Intelligence'),
                    _buildSettingTile(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'AI Provider',
                      subtitle: '${controller.providerName.value}  ·  ${controller.modelName.value.isEmpty ? "Not set" : controller.modelName.value}',
                      isExpanded: expanded == 'AI',
                      onTap: () => _toggleTile('AI'),
                      child: controller.isLoading.value
                          ? const Center(child: CircularProgressIndicator())
                          : _buildAiCardContent(context),
                    ),
                    _buildSectionHeader('App'),
                    _buildSettingTile(
                      icon: Icons.palette_rounded,
                      iconColor: const Color(0xFFF97316),
                      title: 'Theme & Appearance',
                      subtitle: 'Space Grotesk  ·  Light Mode',
                      isExpanded: expanded == 'Theme',
                      onTap: () => _toggleTile('Theme'),
                      child: _buildThemeContent(),
                    ),
                    _buildSettingTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF64748B),
                      title: 'About & Version',
                      subtitle: 'IUNO IoT  ·  v1.0.0-beta.1',
                      isExpanded: expanded == 'Info',
                      onTap: () => _toggleTile('Info'),
                      child: _buildSystemInfoContent(),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Simple calm header ───────────────────────────────
  Widget _buildHeroHeader(DashboardController dash) {
    return Obx(() {
      final brokerOk = dash.isBrokerConnected.value;
      final deviceLive = dash.isDeviceConnected.value;
      final isConnecting = dash.isConnecting.value;

      final Color statusColor = isConnecting
          ? const Color(0xFFF59E0B)
          : deviceLive
              ? const Color(0xFF22C55E)
              : brokerOk
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444);

      final String statusText = isConnecting
          ? 'Connecting…'
          : deviceLive
              ? 'Live'
              : brokerOk
                  ? 'Broker OK'
                  : 'Offline';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Broker, AI & App Settings',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Compact status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPulsingDot(statusColor),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPulsingDot(Color color) {
    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }


  // ── Custom Expandable Setting Tile ──────────────────────
  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
    required bool isExpanded,
    required VoidCallback onTap,
    Color? statusDot,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
        border: Border.all(
          color: isExpanded ? iconColor.withValues(alpha: 0.25) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Left colored accent bar when expanded
            if (isExpanded)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconColor.withValues(alpha: 0.8), iconColor.withValues(alpha: 0.2)],
                  ),
                ),
              ),
            InkWell(
              onTap: onTap,
              splashColor: iconColor.withValues(alpha: 0.06),
              highlightColor: iconColor.withValues(alpha: 0.03),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (statusDot != null) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 5),
                                  decoration: BoxDecoration(
                                    color: statusDot,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  subtitle,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? iconColor : const Color(0xFFCBD5E1),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border(
                    top: BorderSide(color: iconColor.withValues(alpha: 0.1), width: 1),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: child,
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Simulation & Demo Mode Content ───────────────────
  Widget _buildSimulationContent(DashboardController dash) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable Demo Mode',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0A1F30),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generates realistic simulated data for testing when the broker is disconnected.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color: const Color(0xFF888888),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Obx(() => Switch.adaptive(
                    value: dash.isDemoMode.value,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF0D9488),
                    onChanged: (val) {
                      dash.setDemoMode(val);
                      Get.snackbar(
                        val ? 'Demo Mode Active' : 'Real Mode Active',
                        val 
                            ? 'Simulated sensors have been loaded.'
                            : 'Simulated sensors cleared. Waiting for real MQTT data stream.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: val ? const Color(0xFF0D9488) : Colors.black,
                        colorText: Colors.white,
                        borderRadius: 14,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      );
                    },
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ─── MQTT Broker Content ──────────────────────────────
  Widget _buildBrokerCardContent(DashboardController dash) {
    return Obx(() {
      final protocol = controller.connectionProtocol.value;
      final preset = controller.mqttPreset.value;
      final useTls = controller.mqttUseTls.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Protocol Selector ──
          _buildSectionLabel('Connection Protocol'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildChoiceCard(
                  label: 'MQTT',
                  hint: 'TCP / TLS socket',
                  icon: Icons.hub_rounded,
                  isSelected: protocol == 'MQTT',
                  onTap: () => controller.connectionProtocol.value = 'MQTT',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceCard(
                  label: 'HTTP',
                  hint: 'REST API',
                  icon: Icons.language_rounded,
                  isSelected: protocol == 'HTTP',
                  onTap: () => controller.connectionProtocol.value = 'HTTP',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (protocol == 'HTTP') ...[
            _buildTextField(
              ctrl: httpUrlController,
              label: 'ESP32 HTTP Target URL',
              hint: 'e.g., http://192.168.10.100',
            ),
            const SizedBox(height: 20),
            _buildSaveBrokerButton(),
          ] else ...[
            // ── Preset Selector ──
            _buildSectionLabel('Broker Preset'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildChoiceCard(
                    label: 'Docker',
                    hint: 'Port 1883 • No TLS',
                    icon: Icons.developer_board_rounded,
                    isSelected: preset == 'Docker',
                    onTap: () {
                      controller.mqttPreset.value = 'Docker';
                      mqttHostController.text = '192.168.10.3';
                      mqttPortController.text = '1883';
                      controller.mqttUseTls.value = false;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildChoiceCard(
                    label: 'HiveMQ',
                    hint: 'Port 8883 • TLS',
                    icon: Icons.cloud_queue_rounded,
                    isSelected: preset == 'HiveMQ',
                    onTap: () {
                      controller.mqttPreset.value = 'HiveMQ';
                      controller.mqttUseTls.value = true;
                      mqttPortController.text = '8883';
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildChoiceCard(
                    label: 'Custom',
                    hint: 'Manual setup',
                    icon: Icons.tune_rounded,
                    isSelected: preset == 'Custom',
                    onTap: () => controller.mqttPreset.value = 'Custom',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Single Broker Host Field ──
            _buildTextField(
              ctrl: mqttHostController,
              label: preset == 'HiveMQ' ? 'HiveMQ Cluster URL' : 'Broker Host / IP',
              hint: preset == 'HiveMQ'
                  ? 'xxxxxxxx.s1.eu.hivemq.cloud'
                  : '192.168.10.3',
              prefixIcon: useTls ? Icons.lock_rounded : Icons.wifi_rounded,
            ),
            const SizedBox(height: 14),

            // ── Port + TLS Toggle row ──
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    ctrl: mqttPortController,
                    label: 'Port',
                    hint: useTls ? '8883' : '1883',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: _buildTlsToggleTile(useTls),
                ),
              ],
            ),

            // ── Auth fields (HiveMQ / Custom / TLS) ──
            if (preset == 'HiveMQ' || preset == 'Custom' || useTls) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      ctrl: mqttUsernameController,
                      label: 'Username',
                      hint: 'your_username',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      ctrl: mqttPasswordController,
                      label: 'Password',
                      hint: '••••••••',
                      isObscure: true,
                      prefixIcon: Icons.key_outlined,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),
            _buildSaveBrokerButton(),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 16),
            _buildStatusAndConnectSection(dash),
          ],
        ],
      );
    });
  }

  Widget _buildTlsToggleTile(bool useTls) {
    return GestureDetector(
      onTap: () {
        final next = !controller.mqttUseTls.value;
        controller.mqttUseTls.value = next;
        if (next && mqttPortController.text == '1883') {
          mqttPortController.text = '8883';
        } else if (!next && mqttPortController.text == '8883') {
          mqttPortController.text = '1883';
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: useTls ? const Color(0xFF0A1F30) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: useTls ? const Color(0xFF0A1F30) : const Color(0xFFE8E8E8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              useTls ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 15,
              color: useTls ? Colors.white : const Color(0xFF888888),
            ),
            const SizedBox(width: 6),
            Text(
              useTls ? 'TLS ON' : 'TLS OFF',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: useTls ? Colors.white : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String label,
    required String hint,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A1F30) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A1F30) : const Color(0xFFE8E8E8),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF555555),
              size: 20,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                color: isSelected ? Colors.white60 : const Color(0xFF999999),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF888888),
        letterSpacing: 0.5,
      ),
    );
  }

  void _doSaveBrokerSettings() {
    final host = mqttHostController.text.trim();
    controller.saveBrokerSettings(
      protocol: controller.connectionProtocol.value,
      preset: controller.mqttPreset.value,
      host: host,
      port: int.tryParse(mqttPortController.text.trim()) ?? 1883,
      wsPort: 9001,
      useTls: controller.mqttUseTls.value,
      tlsHost: host, // single host field: saved to both keys
      tlsWsUrl: '',
      httpUrl: httpUrlController.text.trim(),
      username: mqttUsernameController.text.trim(),
      password: mqttPasswordController.text,
    );
  }

  Widget _buildSaveBrokerButton() {
    return _buildPrimaryButton(
      label: 'Save Settings',
      onTap: _doSaveBrokerSettings,
    );
  }

  Widget _buildStatusAndConnectSection(DashboardController dash) {
    return Obx(() {
      final isConnecting = dash.isConnecting.value;
      final brokerOk = dash.isBrokerConnected.value;
      final deviceLive = dash.isDeviceConnected.value;

      // Status chip config
      Color chipBg, chipFg;
      String chipLabel;
      IconData chipIcon;
      if (isConnecting) {
        chipBg = const Color(0xFFFEF3C7); chipFg = const Color(0xFF92400E);
        chipLabel = 'Connecting…'; chipIcon = Icons.sync_rounded;
      } else if (deviceLive) {
        chipBg = const Color(0xFFD1FAE5); chipFg = const Color(0xFF065F46);
        chipLabel = 'Live'; chipIcon = Icons.sensors_rounded;
      } else if (brokerOk) {
        chipBg = const Color(0xFFFFF3CD); chipFg = const Color(0xFF8A5700);
        chipLabel = 'Broker OK'; chipIcon = Icons.cloud_done_rounded;
      } else {
        chipBg = const Color(0xFFFFE4E4); chipFg = const Color(0xFF991B1B);
        chipLabel = 'Offline'; chipIcon = Icons.cloud_off_rounded;
      }

      // Button config
      final bool isDisconnected = !brokerOk && !isConnecting;
      final btnLabel = isConnecting ? 'Connecting…' : brokerOk ? 'Disconnect' : 'Connect Now';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(chipIcon, color: chipFg, size: 15),
                const SizedBox(width: 6),
                Text(
                  chipLabel,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: chipFg,
                  ),
                ),
              ],
            ),
          ),

          if (brokerOk && !deviceLive) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  width: 13, height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF888888)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Scanning for ESP32 nodes…',
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, color: const Color(0xFF888888)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Connect / Disconnect button
          GestureDetector(
            onTap: isConnecting ? null : () async {
              if (brokerOk) {
                await dash.toggleConnection();
              } else {
                _doSaveBrokerSettings();
                await dash.toggleConnection();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: isDisconnected
                    ? const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: isDisconnected ? null : (brokerOk ? const Color(0xFFFFECEC) : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: isConnecting
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        btnLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: brokerOk ? const Color(0xFFEF4444) : Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      );
    });
  }

  // ─── AI API Provider Content ──────────────────────────
  Widget _buildAiCardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configure your preferred AI API provider for the Assistant.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            color: const Color(0xFF888888),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _buildProviderSelection(),
        const SizedBox(height: 18),
        _buildTextField(
          ctrl: baseUrlController,
          label: 'Base URL',
          hint: 'https://openrouter.ai/api/v1',
          onChanged: (val) {
            controller.baseUrl.value = val.trim();
          },
        ),
        const SizedBox(height: 14),
        _buildTextField(
          ctrl: apiKeyController,
          label: 'API Key',
          hint: 'Enter your API key',
          isObscure: true,
          onChanged: (val) {
            controller.apiKey.value = val.trim();
          },
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Obx(() {
                final key = controller.apiKey.value.trim();
                if (key.isEmpty) {
                  return _buildLockedModelField(
                    label: 'Model',
                    hint: 'Enter API Key to unlock model list',
                  );
                }

                if (controller.isTestingConnection.value) {
                  return _buildLoadingModelField(label: 'Model');
                }

                final models = controller.availableModels;
                if (models.isEmpty) {
                  return _buildTextField(
                    ctrl: modelController,
                    label: 'Model',
                    hint: 'e.g., openai/gpt-4o',
                    onChanged: (val) {
                      controller.modelName.value = val.trim();
                    },
                  );
                }

                final cur = models.contains(controller.modelName.value)
                    ? controller.modelName.value
                    : models.first;

                return _buildSearchableDropdown(
                  label: 'Model',
                  value: cur,
                  items: models.toList(),
                  onChanged: (val) {
                    if (val != null) {
                      controller.modelName.value = val;
                    }
                  },
                );
              }),
            ),
            const SizedBox(width: 12),
            Obx(() => _buildOutlineButton(
                  label: 'Test',
                  isLoading: controller.isTestingConnection.value,
                  onTap: () {
                    if (baseUrlController.text.isNotEmpty &&
                        apiKeyController.text.isNotEmpty) {
                      controller.testConnection(
                        baseUrlController.text,
                        apiKeyController.text,
                      );
                    } else {
                      Get.snackbar(
                        'Missing Info',
                        'Please enter Base URL and API Key first.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.black,
                        colorText: Colors.white,
                        borderRadius: 14,
                        margin: const EdgeInsets.all(16),
                      );
                    }
                  },
                )),
          ],
        ),
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: 'Save Configuration',
          onTap: () => controller.saveSettings(
            provider: controller.providerName.value,
            url: baseUrlController.text.trim(),
            key: apiKeyController.text.trim(),
            model: modelController.text.trim(),
          ),
        ),
      ],
    );
  }

  // ─── Theme & Aesthetics Content ────────────────────────
  Widget _buildThemeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select App Theme Mode',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Light Mode',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: Center(
                  child: Text(
                    'Dark Mode',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── System Info Content ──────────────────────────────
  Widget _buildSystemInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final host = controller.mqttTlsHost.value.isNotEmpty
              ? controller.mqttTlsHost.value
              : (controller.mqttHost.value.isNotEmpty
                  ? controller.mqttHost.value
                  : 'Not configured');
          final port = controller.mqttPort.value;
          final protocolLabel = controller.mqttUseTls.value ? 'MQTTS' : 'MQTT';
          final brokerTarget = '$host ($protocolLabel Port $port)';

          return Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2),
            },
            children: [
              _buildInfoRow('OS Version', controller.osVersion.value),
              _buildInfoRow('Device Model', controller.deviceModel.value),
              _buildInfoRow('CPU Core Count', controller.cpuCoreCount.value),
              _buildInfoRow('Flutter SDK', 'v3.11.4+ (Stable Channel)'),
              _buildInfoRow('Dart SDK', controller.dartVersion.value),
              _buildInfoRow('Broker Target', brokerTarget),
              _buildInfoRow('GitHub Repo', 'WilyArd/Iuno-Project'),
            ],
          );
        }),
        const SizedBox(height: 16),
        // GitHub Link Card
        GestureDetector(
          onTap: () async {
            final uri = Uri.parse('https://github.com/WilyArd/Iuno-Project');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.code_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View Source Code',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'github.com/WilyArd/Iuno-Project',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.open_in_new_rounded,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildInfoRow(String label, String val) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF777777),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            val,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared widgets ────────────────────────────────────
  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    final bg = isDestructive ? const Color(0xFFFFECEC) : Colors.black;
    final fg = isDestructive ? const Color(0xFFEF4444) : Colors.white;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: fg,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDDDDD), width: 1.5),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    bool isObscure = false,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: isObscure,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: GoogleFonts.spaceGrotesk(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: const Color(0xFFBBBBBB),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: const Color(0xFF999999))
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildLockedModelField({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F1F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF888888),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: const Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingModelField({required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Detecting available models…',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: const Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provider',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final selected = controller.providerName.value;
          return Row(
            children: [
              Expanded(child: _buildProviderOption('OpenRouter', Icons.alt_route_rounded, selected == 'OpenRouter')),
              const SizedBox(width: 8),
              Expanded(child: _buildProviderOption('OpenAI', Icons.auto_awesome_rounded, selected == 'OpenAI')),
              const SizedBox(width: 8),
              Expanded(child: _buildProviderOption('Local/Custom', Icons.dns_rounded, selected == 'Local/Custom')),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildProviderOption(String name, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        controller.providerName.value = name;
        if (name == 'OpenRouter') {
          baseUrlController.text = 'https://openrouter.ai/api/v1';
          controller.baseUrl.value = 'https://openrouter.ai/api/v1';
        } else if (name == 'OpenAI') {
          baseUrlController.text = 'https://api.openai.com/v1';
          controller.baseUrl.value = 'https://api.openai.com/v1';
        } else {
          controller.baseUrl.value = baseUrlController.text;
        }
        if (controller.apiKey.value.trim().isEmpty) {
          controller.availableModels.clear();
          controller.modelName.value = '';
        } else {
          if (controller.availableModels.isNotEmpty) {
            controller.modelName.value = controller.availableModels.first;
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFE8E8E8),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF777777),
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF555555),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchableDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 6),
        _SearchableDropdown(value: value, items: items, onChanged: onChanged),
      ],
    );
  }
}

// ─── Searchable dropdown (restyled) ─────────────────────
class _SearchableDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  const _SearchableDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<_SearchableDropdown> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filtered = [];
  bool _isOpen = false;
  late String? _selected;
  final _overlayController = OverlayPortalController();
  final _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _selected = widget.value;
    _filtered = widget.items;
  }

  @override
  void didUpdateWidget(_SearchableDropdown old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _selected = widget.value;
  }

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
      _overlayController.toggle();
    });
    if (_isOpen) {
      _searchController.clear();
      _filtered = widget.items;
    }
  }

  void _filter(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? widget.items
          : widget.items
              .where((m) => m.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  void _select(String val) {
    setState(() {
      _selected = val;
      _isOpen = false;
    });
    _overlayController.hide();
    widget.onChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) {
          final renderBox = this.context.findRenderObject() as RenderBox;
          final size = renderBox.size;
          return CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: Container(
                  width: size.width,
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: _filter,
                          style: GoogleFonts.spaceGrotesk(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search model…',
                            hintStyle: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: const Color(0xFFBBBBBB),
                            ),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFFAAAAAA)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                            filled: true,
                            fillColor: const Color(0xFFF4F6FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: const Color(0xFFF0F0F0)),
                      Flexible(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final model = _filtered[i];
                              final isSel = model == _selected;
                              return InkWell(
                                onTap: () => _select(model),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 11),
                                  color: isSel
                                      ? const Color(0xFFF0F0F0)
                                      : Colors.transparent,
                                  child: Text(
                                    model,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: isSel
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isOpen ? Colors.black : const Color(0xFFE8E8E8),
                width: _isOpen ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selected ?? 'Select a model…',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: _selected == null
                          ? const Color(0xFFBBBBBB)
                          : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _isOpen
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFFAAAAAA),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
