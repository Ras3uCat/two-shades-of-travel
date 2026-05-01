import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/e_colors.dart';
import 'chatbot_controller.dart';
import 'chatbot_sheet.dart';

/// Floating chat bubble — composited into the root Stack in main.dart.
/// Hidden on all /admin* routes and when sheet is open.
class ChatbotBubble extends StatelessWidget {
  const ChatbotBubble({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is available globally (permanent across routes)
    if (!Get.isRegistered<ChatbotController>()) {
      Get.put(ChatbotController(), permanent: true);
    }

    return Obx(() {
      if (Get.currentRoute.startsWith('/admin')) return const SizedBox.shrink();

      return Positioned(
        right: 20,
        bottom: 20,
        child: FloatingActionButton(
          heroTag: 'chatbot_fab',
          backgroundColor: EColors.primary,
          foregroundColor: EColors.white,
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const ChatbotSheet(),
          ),
          child: const Icon(Icons.chat_bubble_outline_rounded),
        ),
      );
    });
  }
}
