import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/dashboard/views/dashboard_view.dart';
import '../../features/analytics/views/analytics_view.dart';
import '../../features/dashboard/controllers/dashboard_controller.dart';

import '../../features/assistant/views/assistant_view.dart';
import '../../features/system/views/system_view.dart';
import '../../features/system/controllers/system_controller.dart';

class MainLayoutController extends GetxController {
  var selectedIndex = 0.obs;
  late PageController pageController;

  @override
  void onInit() {
    super.onInit();
    // Register SystemController globally so AssistantController can find it
    Get.put(SystemController());
    pageController = PageController(initialPage: selectedIndex.value);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void changeTab(int index) {
    selectedIndex.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void onPageChanged(int index) {
    selectedIndex.value = index;
  }
}

class MainLayout extends StatelessWidget {
  MainLayout({super.key});

  final MainLayoutController controller = Get.put(MainLayoutController());

  final List<Widget> pages = [
    DashboardView(),
    AnalyticsView(),
    AssistantView(),
    SystemView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            return _buildDesktopLayout(context);
          }
          return _buildMobileLayout(context);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 250,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Colors.black, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sensors, color: Colors.black, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      'IUNO',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 32,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              // Nav Items
              Expanded(
                child: Obx(() => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSidebarItem(icon: Icons.router, label: 'DEVICES', index: 0),
                    const SizedBox(height: 8),
                    _buildSidebarItem(icon: Icons.leaderboard, label: 'ANALYTICS', index: 1),
                    const SizedBox(height: 8),
                    _buildSidebarItem(icon: Icons.smart_toy, label: 'AI ASSISTANT', index: 2),
                    const SizedBox(height: 8),
                    _buildSidebarItem(icon: Icons.settings, label: 'SYSTEM', index: 3),

                  ],
                )),
              ),
              // User / Device settings
              GestureDetector(
                onTap: () => _showDeviceBottomSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE600),
                    border: Border(top: BorderSide(color: Colors.black, width: 3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.settings_input_component, color: Colors.black),
                      const SizedBox(width: 12),
                      Text(
                        'CONNECTION',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Main Content
        Expanded(
          child: Column(
            children: [
              // Top Bar
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.notifications_none, color: Colors.black, size: 28),
                    const SizedBox(width: 24),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: controller.pageController,
                  onPageChanged: controller.onPageChanged,
                  physics: const NeverScrollableScrollPhysics(),
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem({required IconData icon, required String label, required int index}) {
    final isActive = controller.selectedIndex.value == index;
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.transparent,
          border: Border.all(color: isActive ? Colors.black : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.black87),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black, width: 3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showDeviceBottomSheet(context),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        const Icon(Icons.sensors, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          'IUNO',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            fontSize: 24,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.account_circle, color: Colors.black),
                ],
              ),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: pages,
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.black, width: 3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: Offset(0, -4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: Icons.router,
                label: 'DEVICES',
                index: 0,
                isActive: controller.selectedIndex.value == 0,
              ),
              _buildBottomNavItem(
                icon: Icons.leaderboard,
                label: 'ANALYTICS',
                index: 1,
                isActive: controller.selectedIndex.value == 1,
              ),
              _buildBottomNavItem(
                icon: Icons.smart_toy,
                label: 'ASSISTANT',
                index: 2,
                isActive: controller.selectedIndex.value == 2,
              ),
              _buildBottomNavItem(
                icon: Icons.settings,
                label: 'SYSTEM',
                index: 3,
                isActive: controller.selectedIndex.value == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeviceBottomSheet(BuildContext context) {
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
    final dashboardController = Get.find<DashboardController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black, width: 3),
            left: BorderSide(color: Colors.black, width: 3),
            right: BorderSide(color: Colors.black, width: 3),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black, offset: Offset(8, 0), blurRadius: 0),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Device Settings',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (dashboardController.isBrokerConnected.value &&
                  !dashboardController.isDeviceConnected.value) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Scanning for nodes...',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              } else if (!dashboardController.isDeviceConnected.value) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.developer_board,
                          size: 32,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dashboardController.deviceName.value.isEmpty
                                    ? 'Unknown Device'
                                    : dashboardController.deviceName.value,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Status: Connected',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF00E676),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
            Obx(
              () => GestureDetector(
                onTap: () {
                  dashboardController.toggleConnection();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: dashboardController.isConnecting.value
                        ? Colors.grey[300]
                        : (dashboardController.isBrokerConnected.value
                              ? const Color(0xFFBA1A1A) // Red for disconnect
                              : const Color(0xFFFFE600)), // Yellow for connect
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      dashboardController.isConnecting.value
                          ? 'CONNECTING...'
                          : (dashboardController.isBrokerConnected.value
                                ? 'DISCONNECT'
                                : 'CONNECT BROKER'),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            dashboardController.isBrokerConnected.value &&
                                !dashboardController.isConnecting.value
                            ? Colors.white
                            : Colors.black,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        transform: isActive
            ? Matrix4.translationValues(0, -6, 0)
            : Matrix4.identity(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFE600) : Colors.transparent,
          border: isActive
              ? Border.all(color: Colors.black, width: 3)
              : Border.all(color: Colors.transparent, width: 3),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Colors.transparent,
                    offset: Offset(0, 0),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.black : Colors.black54),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.black : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
