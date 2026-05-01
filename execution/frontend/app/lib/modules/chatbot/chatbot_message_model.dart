class ChatbotMessage {
  final String role;    // 'user' | 'assistant'
  final String content;

  const ChatbotMessage({required this.role, required this.content});

  Map<String, String> toJson() => {'role': role, 'content': content};
}
