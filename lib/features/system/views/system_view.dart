import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/system_controller.dart';

class SystemView extends StatelessWidget {
  final SystemController controller = Get.find<SystemController>();

  final providerController = TextEditingController();
  final baseUrlController = TextEditingController();
  final apiKeyController = TextEditingController();
  final modelController = TextEditingController();

  SystemView({super.key}) {
    // Populate initial values once loaded
    ever(controller.isLoading, (isLoading) {
      if (!isLoading) {
        baseUrlController.text = controller.baseUrl.value;
        apiKeyController.text = controller.apiKey.value;
        modelController.text = controller.modelName.value;
      }
    });
    
    ever(controller.modelName, (model) {
      if (modelController.text != model) {
        modelController.text = model;
      }
    });
    
    // Also set them if already loaded
    if (!controller.isLoading.value) {
      baseUrlController.text = controller.baseUrl.value;
      apiKeyController.text = controller.apiKey.value;
      modelController.text = controller.modelName.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Settings',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
            if (controller.isLoading.value) {
              return const CircularProgressIndicator();
            }
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(4, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI API Provider Configuration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Configure your preferred AI API provider (e.g., OpenRouter, OpenAI) for the Assistant.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    _buildDropdown(
                      label: 'Provider Name',
                      value: controller.providerName.value.isNotEmpty && controller.providers.contains(controller.providerName.value)
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
                          
                          // Select the first model of the new provider
                          if (controller.availableModels.isNotEmpty) {
                            controller.modelName.value = controller.availableModels.first;
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: baseUrlController,
                      label: 'Base URL',
                      hint: 'e.g., https://openrouter.ai/api/v1',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: apiKeyController,
                      label: 'API Key',
                      hint: 'Enter your API key here',
                      isObscure: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Obx(() {
                            final models = controller.availableModels;
                            if (models.isEmpty) {
                              return _buildTextField(
                                controller: modelController,
                                label: 'Model Name',
                                hint: 'e.g., openai/gpt-4o',
                              );
                            }
                            // After Test Connection: show searchable dropdown
                            final currentVal = models.contains(controller.modelName.value)
                                ? controller.modelName.value
                                : models.first;
                            return _buildSearchableDropdown(
                              label: 'Model Name',
                              value: currentVal,
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
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Colors.black, width: 2),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          ),
                          onPressed: () {
                            if (baseUrlController.text.isNotEmpty && apiKeyController.text.isNotEmpty) {
                              controller.testConnection(baseUrlController.text, apiKeyController.text);
                            } else {
                              Get.snackbar(
                                'Missing Info',
                                'Please enter Base URL and API Key first.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                          child: Obx(() => controller.isTestingConnection.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Test Connection', style: TextStyle(fontWeight: FontWeight.bold))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE600),
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black, width: 2),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      onPressed: () {
                        controller.saveSettings(
                          provider: controller.providerName.value,
                          url: baseUrlController.text.trim(),
                          key: apiKeyController.text.trim(),
                          model: modelController.text.trim(),
                        );
                      },
                      child: const Text(
                        'Save Configuration',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isObscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isObscure,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.black, width: 3),
            ),
            filled: true,
            fillColor: Colors.white,
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.black, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.black, width: 3),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _SearchableDropdown(
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

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
    if (old.value != widget.value) {
      _selected = widget.value;
    }
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
          : widget.items.where((m) => m.toLowerCase().contains(query.toLowerCase())).toList();
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
            offset: Offset(0, size.height + 2),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 0,
                color: Colors.white,
                child: Container(
                  width: size.width,
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, offset: Offset(4, 4)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: _filter,
                          decoration: const InputDecoration(
                            hintText: 'Search model...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: Colors.black, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: Colors.black, width: 2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide: BorderSide(color: Colors.black, width: 2),
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Colors.black),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final model = _filtered[i];
                            final isSelected = model == _selected;
                            return InkWell(
                              onTap: () => _select(model),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                color: isSelected ? const Color(0xFFFFE600) : Colors.transparent,
                                child: Text(
                                  model,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.black,
                width: _isOpen ? 3 : 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selected ?? 'Select a model...',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selected == null ? Colors.grey[500] : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.black),
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
