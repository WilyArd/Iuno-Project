import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/assistant_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

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

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, size: 32, color: Colors.black),
              const SizedBox(width: 12),
              Text(
                'AI ASSISTANT (CLAW)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(4, 4)),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Obx(() => ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.messages.length,
                      itemBuilder: (context, index) {
                        final msg = controller.messages[index];
                        return _buildChatBubble(msg.text, msg.isUser);
                      },
                    )),
                  ),
                  Obx(() {
                    if (controller.isTyping.value) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'AI is typing...',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.black, width: 3)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            style: GoogleFonts.spaceGrotesk(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Type your command...',
                              hintStyle: GoogleFonts.spaceGrotesk(color: Colors.grey),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (val) {
                              controller.sendMessage(val);
                              textController.clear();
                            },
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            controller.sendMessage(textController.text);
                            textController.clear();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE600),
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                              ],
                            ),
                            child: const Icon(Icons.send, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFFFE600) : const Color(0xFFF0F0F0),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
             BoxShadow(color: Colors.black, offset: Offset(2, 2)),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
