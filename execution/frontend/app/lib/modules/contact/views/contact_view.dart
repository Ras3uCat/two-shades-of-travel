import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_env.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/seo_wrapper.dart';
import '../controllers/contact_controller.dart';

class ContactView extends GetView<ContactController> {
  const ContactView({super.key});

  @override
  Widget build(BuildContext context) {
    final nameCtrl    = TextEditingController();
    final emailCtrl   = TextEditingController();
    final messageCtrl = TextEditingController();

    void syncControllers() {
      controller.name.value    = nameCtrl.text;
      controller.email.value   = emailCtrl.text;
      controller.message.value = messageCtrl.text;
    }

    nameCtrl.addListener(syncControllers);
    emailCtrl.addListener(syncControllers);
    messageCtrl.addListener(syncControllers);

    return SeoWrapper(
      title: 'Contact',
      description: 'Get in touch with ${AppEnv.clientName}.',
      child: AppShell(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ESpacing.pagePaddingH,
                  vertical: ESpacing.sectionGap,
                ),
                child: Obx(() {
                  if (controller.sent.value) return _SuccessState();
                  return _FormState(
                    nameCtrl: nameCtrl,
                    emailCtrl: emailCtrl,
                    messageCtrl: messageCtrl,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormState extends GetView<ContactController> {
  const _FormState({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.messageCtrl,
  });
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController messageCtrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Get In Touch', style: ETextStyles.displayMd),
        const SizedBox(height: ESpacing.sm),
        Text(
          'We\'d love to hear from you. Send us a message and we\'ll respond as soon as possible.',
          style: ETextStyles.bodyMuted,
        ),
        const SizedBox(height: ESpacing.xxl),

        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
        const SizedBox(height: ESpacing.md),

        TextField(
          controller: emailCtrl,
          decoration: const InputDecoration(labelText: 'Email Address'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: ESpacing.md),

        TextField(
          controller: messageCtrl,
          decoration: const InputDecoration(labelText: 'Message'),
          maxLines: 5,
        ),

        Obx(() {
          if (controller.error.value.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: ESpacing.sm),
            child: Text(controller.error.value,
                style: ETextStyles.bodySm.copyWith(color: EColors.error)),
          );
        }),

        const SizedBox(height: ESpacing.xl),

        Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.canSubmit && !controller.loading.value
                ? controller.submit
                : null,
            child: controller.loading.value
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Send Message'),
          ),
        )),
      ],
    );
  }
}

class _SuccessState extends GetView<ContactController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 72, color: EColors.primary),
        const SizedBox(height: ESpacing.lg),
        Text('Message Sent!', style: ETextStyles.h1, textAlign: TextAlign.center),
        const SizedBox(height: ESpacing.md),
        Text(
          'Thank you for reaching out. We\'ll be in touch shortly.',
          style: ETextStyles.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ESpacing.xl),
        OutlinedButton(onPressed: controller.reset, child: const Text('Send Another')),
      ],
    );
  }
}
