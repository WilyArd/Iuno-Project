import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/system_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class SystemView extends StatelessWidget {
  final SystemController controller = Get.find<SystemController>();

  final providerController = TextEditingController();
  final baseUrlController = TextEditingController();
  final apiKeyController = TextEditingController();
  final modelController = TextEditingController();

  SystemView({super.key}) {
    ever(controller.isLoading, (isLoading) {
      if (!isLoading) {
        baseUrlController.text = controller.baseUrl.value;
        apiKeyController.text = controller.apiKey.value;
        modelController.text = controller.modelName.value;
      }
    });
    ever(controller.modelName, (model) {
      if (modelController.text != model) modelController.text = model;
    });
    if (!controller.isLoading.value) {
      baseUrlController.text = controller.baseUrl.value;
      apiKeyController.text = controller.apiKey.value;
      modelController.text = controller.modelName.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title
            Text(
              'System',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your broker connection and AI settings.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: const Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 24),

            // ── Broker Connection Section ─────────────────
            _buildSectionLabel('Broker Connection'),
            const SizedBox(height: 10),
            _buildBrokerCard(context),
            const SizedBox(height: 24),

            // ── AI API Section ───────────────────────────
            _buildSectionLabel('AI API Provider'),
            const SizedBox(height: 10),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildAiCard(context);
            }),
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
        letterSpacing: 1,
      ),
    );
  }

  // ─── Broker card (moved from logo hotspot) ──────────
  Widget _buildBrokerCard(BuildContext context) {
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
    final dash = Get.find<DashboardController>();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status row
          Obx(() {
            final isConnecting = dash.isConnecting.value;
            final brokerOk = dash.isBrokerConnected.value;
            final deviceLive = dash.isDeviceConnected.value;

            Color dotColor;
            Color dotBg;
            String chipLabel;
            if (isConnecting) {
              dotColor = const Color(0xFF9A7700);
              dotBg = const Color(0xFFFFF9C4);
              chipLabel = 'Connecting';
            } else if (deviceLive) {
              dotColor = const Color(0xFF065F46);
              dotBg = const Color(0xFFD1FAE5);
              chipLabel = 'Live';
            } else if (brokerOk) {
              dotColor = const Color(0xFF8A5700);
              dotBg = const Color(0xFFFFF3CD);
              chipLabel = 'Broker OK';
            } else {
              dotColor = const Color(0xFF991B1B);
              dotBg = const Color(0xFFFFE4E4);
              chipLabel = 'Offline';
            }

            return Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hub_rounded, color: Color(0xFF555555), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MQTT Broker',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '192.168.10.3 : 1883',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          color: const Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: dotBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        chipLabel,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: dotColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 6),
          Obx(() {
            if (dash.isBrokerConnected.value && !dash.isDeviceConnected.value) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF888888)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Scanning for nodes…',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 16),
          // Connect / Disconnect button
          Obx(() => _buildPrimaryButton(
                label: dash.isConnecting.value
                    ? 'Connecting…'
                    : dash.isBrokerConnected.value
                        ? 'Disconnect'
                        : 'Connect Broker',
                onTap: dash.toggleConnection,
                isDestructive: dash.isBrokerConnected.value && !dash.isConnecting.value,
                isLoading: dash.isConnecting.value,
              )),
        ],
      ),
    );
  }

  // ─── AI Config card ─────────────────────────────────
  Widget _buildAiCard(BuildContext context) {
    return _card(
      child: Column(
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
          _buildDropdown(
            label: 'Provider',
            value: controller.providerName.value.isNotEmpty &&
                    controller.providers.contains(controller.providerName.value)
                ? controller.providerName.value
                : controller.providers.first,
            items: controller.providers,
            onChanged: (val) {
              if (val != null) {
                controller.providerName.value = val;
                if (val == 'OpenRouter') {
                  baseUrlController.text = 'https://openrouter.ai/api/v1';
                } else if (val == 'OpenAI') {
                  baseUrlController.text = 'https://api.openai.com/v1';
                }
                if (controller.availableModels.isNotEmpty) {
                  controller.modelName.value = controller.availableModels.first;
                }
              }
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            ctrl: baseUrlController,
            label: 'Base URL',
            hint: 'https://openrouter.ai/api/v1',
          ),
          const SizedBox(height: 14),
          _buildTextField(
            ctrl: apiKeyController,
            label: 'API Key',
            hint: 'Enter your API key',
            isObscure: true,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Obx(() {
                  final models = controller.availableModels;
                  if (models.isEmpty) {
                    return _buildTextField(
                      ctrl: modelController,
                      label: 'Model',
                      hint: 'e.g., openai/gpt-4o',
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
                        modelController.text = val;
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
      ),
    );
  }

  // ─── Shared styled widgets ──────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

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
          style: GoogleFonts.spaceGrotesk(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: const Color(0xFFBBBBBB),
            ),
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

  Widget _buildDropdown({
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
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: GoogleFonts.spaceGrotesk(fontSize: 14, color: Colors.black),
          decoration: InputDecoration(
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
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
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
