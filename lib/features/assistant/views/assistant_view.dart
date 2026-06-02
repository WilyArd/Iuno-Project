import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/assistant_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../system/controllers/system_controller.dart';

class AssistantView extends StatelessWidget {
  AssistantView({super.key});

  final AssistantController controller = Get.put(AssistantController());
  final TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Ensure dashboard controller is available
    if (!Get.isRegistered<DashboardController>()) {
      Get.put(DashboardController());
    }
    final systemCtrl = Get.find<SystemController>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Elegant Assistant Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE), // Soft blue bg
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF0EA5E9), // Cyan/Blue icon
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Assistant',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0A1F30), // Brand Navy
                        letterSpacing: -0.5,
                      ),
                    ),
                    Obx(() {
                      final prov = systemCtrl.providerName.value;
                      final model = systemCtrl.modelName.value;
                      final isKeyEmpty = systemCtrl.apiKey.value.trim().isEmpty;
                      return Text(
                        isKeyEmpty
                            ? 'Offline • Configure API Key in System'
                            : 'Online • Powered by $prov ($model)',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isKeyEmpty ? const Color(0xFFEF4444) : const Color(0xFF0D9488),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    // Chat messages list
                    Expanded(
                      child: Obx(() => ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: controller.messages.length,
                        itemBuilder: (context, index) {
                          final msg = controller.messages[index];
                          return _buildChatBubble(msg.text, msg.isUser);
                        },
                      )),
                    ),
                    
                    // Typist thinking indicator
                    Obx(() {
                      if (controller.isTyping.value) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Assistant is thinking…',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    
                    // Input Text Field Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFEEEEEE), width: 1.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F8FA),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                controller: textController,
                                style: GoogleFonts.spaceGrotesk(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Ask assistant or type command…',
                                  hintStyle: GoogleFonts.spaceGrotesk(
                                    color: const Color(0xFFBBBBBB),
                                    fontSize: 13,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    controller.sendMessage(val);
                                    textController.clear();
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              if (textController.text.trim().isNotEmpty) {
                                controller.sendMessage(textController.text);
                                textController.clear();
                              }
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0A1F30), // Brand Navy
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    final bg = isUser ? const Color(0xFF0A1F30) : const Color(0xFFF1F5F9);
    final fg = isUser ? Colors.white : const Color(0xFF1E293B);
    final border = isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: border,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.spaceGrotesk(
            color: fg,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
