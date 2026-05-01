import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/master_controller.dart';

class ChatbotConfigSection extends StatefulWidget {
  const ChatbotConfigSection({super.key, required this.controller});
  final MasterController controller;

  @override
  State<ChatbotConfigSection> createState() => _ChatbotConfigSectionState();
}

class _ChatbotConfigSectionState extends State<ChatbotConfigSection> {
  late final TextEditingController _welcome;
  late final TextEditingController _prompt;

  @override
  void initState() {
    super.initState();
    final c = widget.controller.config;
    _welcome = TextEditingController(
        text: c['chatbot_welcome_message'] as String? ?? 'Hi! How can I help you today?');
    _prompt = TextEditingController(
        text: c['chatbot_system_prompt'] as String? ?? '');
  }

  @override
  void dispose() {
    _welcome.dispose();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Chatbot', style: ETextStyles.h3),
          const Spacer(),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.secondary,
              shape: const RoundedRectangleBorder(),
            ),
            child: Text('SAVE', style: ETextStyles.button),
          ),
        ]),
        const SizedBox(height: ESpacing.md),
        TextField(
          controller: _welcome,
          style: ETextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'Welcome message',
            labelStyle: ETextStyles.inputLabel,
            hintText: 'Hi! How can I help you today?',
          ),
        ),
        const SizedBox(height: ESpacing.md),
        TextField(
          controller: _prompt,
          style: ETextStyles.inputText,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: 'Custom system prompt (optional)',
            labelStyle: ETextStyles.inputLabel,
            hintText: 'You are a friendly assistant for [Business]. '
                'Always recommend booking online. '
                'Never discuss competitor pricing.',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    await widget.controller.saveConfig({
      'chatbot_welcome_message': _welcome.text,
      'chatbot_system_prompt':   _prompt.text.isEmpty ? null : _prompt.text,
    });
    Get.snackbar('Saved', 'Chatbot settings updated.',
        backgroundColor: EColors.primary.withValues(alpha: 0.9),
        colorText: EColors.secondary);
  }
}
