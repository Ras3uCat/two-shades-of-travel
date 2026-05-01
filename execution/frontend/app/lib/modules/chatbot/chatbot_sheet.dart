import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/app_env.dart';
import '../../core/theme/e_colors.dart';
import '../../core/theme/e_spacing.dart';
import '../../core/theme/e_text_styles.dart';
import '../home/controllers/home_controller.dart';
import 'chatbot_controller.dart';
import 'chatbot_message_model.dart';

class ChatbotSheet extends GetView<ChatbotController> {
  const ChatbotSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final inputCtrl = TextEditingController();
    final scrollCtrl = ScrollController();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle + header
          Container(
            decoration: BoxDecoration(
              color: EColors.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: ESpacing.md, vertical: ESpacing.sm),
            child: Column(
              children: [
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: ESpacing.sm),
                  decoration: BoxDecoration(
                    color: EColors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(children: [
                  Text('Chat with us', style: ETextStyles.bodyMd.copyWith(
                    color: EColors.white, fontWeight: FontWeight.w600,
                  )),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ]),
              ],
            ),
          ),

          // Message list
          Expanded(
            child: Obx(() {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollCtrl.hasClients) {
                  scrollCtrl.animateTo(
                    scrollCtrl.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                }
              });
              return ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(ESpacing.md),
                children: [
                  if (controller.messages.isEmpty)
                    Center(
                      child: Text(
                        AppEnv.chatbotFull
                            ? (Get.find<HomeController>().content['chatbot_welcome_message']
                                    as String? ??
                                'Hi! How can I help you today?')
                            : 'Ask me anything about our services, hours, or how to book!',
                        style: ETextStyles.bodyMd.copyWith(color: EColors.onSurfaceMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ...controller.messages.map((m) => _MessageBubble(message: m)),
                  if (controller.isLoading.value)
                    const Padding(
                      padding: EdgeInsets.only(top: ESpacing.sm),
                      child: _TypingIndicator(),
                    ),
                ],
              );
            }),
          ),

          // Input row
          Container(
            color: EColors.surface,
            padding: const EdgeInsets.fromLTRB(
              ESpacing.md, ESpacing.sm, ESpacing.sm, ESpacing.md,
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: inputCtrl,
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ESpacing.md, vertical: ESpacing.sm,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (v) {
                    controller.sendMessage(v);
                    inputCtrl.clear();
                  },
                ),
              ),
              const SizedBox(width: ESpacing.sm),
              Obx(() => IconButton.filled(
                onPressed: controller.isLoading.value
                    ? null
                    : () {
                        controller.sendMessage(inputCtrl.text);
                        inputCtrl.clear();
                      },
                icon: const Icon(Icons.send),
                style: IconButton.styleFrom(backgroundColor: EColors.primary),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatbotMessage message;
  const _MessageBubble({required this.message});

  bool get isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: ESpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: ESpacing.md, vertical: ESpacing.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? EColors.primary : EColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? null : Border.all(color: EColors.divider),
        ),
        child: Text(
          message.content,
          style: ETextStyles.bodyMd.copyWith(
            color: isUser ? EColors.white : EColors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ESpacing.md, vertical: ESpacing.sm),
        decoration: BoxDecoration(
          color: EColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EColors.divider),
        ),
        child: const SizedBox(
          width: 40, height: 16,
          child: _DotsAnimation(),
        ),
      ),
    );
  }
}

class _DotsAnimation extends StatefulWidget {
  const _DotsAnimation();

  @override
  State<_DotsAnimation> createState() => _DotsAnimationState();
}

class _DotsAnimationState extends State<_DotsAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final step = (_ctrl.value * 3).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (i) => Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: EColors.onSurfaceMuted.withValues(
                alpha: i == step ? 1.0 : 0.3,
              ),
            ),
          )),
        );
      },
    );
  }
}
