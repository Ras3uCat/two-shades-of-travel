import 'dart:math';
import 'package:get/get.dart';
import '../../shared/services/supabase_service.dart';
import 'chatbot_message_model.dart';

String _generateSessionId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random();
  return List.generate(24, (_) => chars[rng.nextInt(chars.length)]).join();
}

class ChatbotController extends GetxController {
  final messages  = <ChatbotMessage>[].obs;
  final isLoading = false.obs;
  final isOpen    = false.obs;

  final String sessionId = _generateSessionId();

  void toggle() => isOpen.value = !isOpen.value;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isLoading.value) return;

    messages.add(ChatbotMessage(role: 'user', content: text.trim()));
    isLoading.value = true;

    try {
      final history = messages
          .map((m) => m.toJson())
          .toList();

      final res = await SupabaseService.client.functions.invoke(
        'chat',
        body: {
          'message':    text.trim(),
          'session_id': sessionId,
          'history':    history,
        },
      );

      final reply = (res.data as Map<String, dynamic>?)?['reply'] as String? ?? '';
      if (reply.isNotEmpty) {
        messages.add(ChatbotMessage(role: 'assistant', content: reply));
      }
    } catch (_) {
      messages.add(const ChatbotMessage(
        role: 'assistant',
        content: 'Sorry, something went wrong. Please try again.',
      ));
    } finally {
      isLoading.value = false;
    }
  }
}
