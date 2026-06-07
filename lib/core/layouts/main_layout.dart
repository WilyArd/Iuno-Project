import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/dashboard/views/dashboard_view.dart';
import '../../features/analytics/views/analytics_view.dart';
import '../../features/assistant/views/assistant_view.dart';
import '../../features/system/views/system_view.dart';
import '../../features/system/controllers/system_controller.dart';

class MainLayoutController extends GetxController {
  var selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    Get.put(SystemController());
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }
}

class MainLayout extends StatelessWidget {
  MainLayout({super.key});

  final MainLayoutController controller = Get.put(MainLayoutController());

  final List<Widget> pages = [
    DashboardView(),
    AnalyticsView(),
    // AI Assistant: visible in debug/dev mode only
    if (kDebugMode) AssistantView(),
    SystemView(),
  ];

  // Navigation tab definitions — mirrors `pages` order.
  // Assistant tab is only included in debug/dev builds.
  List<Map<String, dynamic>> get _tabItems => [
    {'icon': Icons.sensors_rounded, 'label': 'Devices'},
    {'icon': Icons.bar_chart_rounded, 'label': 'Analytics'},
    if (kDebugMode) {'icon': Icons.auto_awesome_rounded, 'label': 'Assistant'},
    {'icon': Icons.settings_rounded, 'label': 'System'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
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

  // ─── Desktop ───────────────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.black.withValues(alpha: 0.08), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo — purely decorative, no tap action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'iuno',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0A1F30), // Official Brand Navy
                        fontWeight: FontWeight.w700,
                        fontSize: 26,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 12),
              // Nav Items
              Expanded(
                child: Obx(() => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: List.generate(_tabItems.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: _buildSidebarItem(
                              icon: _tabItems[i]['icon'] as IconData,
                              label: _tabItems[i]['label'] as String,
                              index: i,
                            ),
                          );
                        }),
                      ),
                    )),
              ),
            ],
          ),
        ),
        // Main Content
        Expanded(
          child: Column(
            children: [
              _buildDesktopTopBar(),
              Expanded(
                child: Obx(() => IndexedStack(
                  index: controller.selectedIndex.value,
                  children: pages,
                )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.07), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF555555), size: 24),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({required IconData icon, required String label, required int index}) {
    final isActive = controller.selectedIndex.value == index;
    return GestureDetector(
      onTap: () => controller.changeTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF0F0F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.black : const Color(0xFF888888),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.black : const Color(0xFF888888),
                fontSize: 14,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Mobile ────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    final bool isKeyboardVisible = View.of(context).viewInsets.bottom > 0;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo — no tap action
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'iuno',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0A1F30), // Official Brand Navy
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF333333), size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() => IndexedStack(
        index: controller.selectedIndex.value,
        children: pages,
      )),
      bottomNavigationBar: isKeyboardVisible ? null : _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabItems.length, (i) {
              return _buildBottomNavItem(
                icon: _tabItems[i]['icon'] as IconData,
                label: _tabItems[i]['label'] as String,
                index: i,
                isActive: controller.selectedIndex.value == i,
              );
            }),
          ),
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
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFFE600) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isActive ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA),
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
