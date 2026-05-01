import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/newsletter_controller.dart';

/// Embeddable newsletter form — can be dropped into any view.
/// Manages its own TextEditingControllers via StatefulWidget.
/// Requires NewsletterController to be registered.
class NewsletterFormWidget extends StatefulWidget {
  const NewsletterFormWidget({super.key});

  @override
  State<NewsletterFormWidget> createState() => _NewsletterFormWidgetState();
}

class _NewsletterFormWidgetState extends State<NewsletterFormWidget> {
  late final NewsletterController _ctrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl      = Get.find<NewsletterController>();
    _emailCtrl = TextEditingController();
    _nameCtrl  = TextEditingController();
    _emailCtrl.addListener(() => _ctrl.email.value = _emailCtrl.text);
    _nameCtrl.addListener(()  => _ctrl.name.value  = _nameCtrl.text);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_ctrl.isSuccess.value) return _SuccessCard(onReset: _ctrl.reset);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _InputField(
            controller: _emailCtrl,
            label: 'Email address',
            hint: 'you@example.com',
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: ESpacing.sm),
          _InputField(
            controller: _nameCtrl,
            label: 'First name (optional)',
            hint: 'Alex',
          ),
          if (_ctrl.error.value.isNotEmpty) ...[
            const SizedBox(height: ESpacing.sm),
            Text(
              _ctrl.error.value,
              style: ETextStyles.bodySm.copyWith(color: EColors.error),
            ),
          ],
          const SizedBox(height: ESpacing.md),
          Obx(() => ElevatedButton(
                onPressed: _ctrl.isSubmitting.value ? null : _ctrl.subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: EColors.secondary,
                  disabledBackgroundColor: EColors.primary.withValues(alpha: 0.5),
                  shape: const RoundedRectangleBorder(),
                  padding: const EdgeInsets.symmetric(vertical: ESpacing.md),
                ),
                child: _ctrl.isSubmitting.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('SUBSCRIBE', style: ETextStyles.button),
              )),
        ],
      );
    });
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, color: EColors.primary, size: 40),
        const SizedBox(height: ESpacing.md),
        Text("You're on the list.", style: ETextStyles.h3),
        const SizedBox(height: ESpacing.xs),
        Text(
          'Check your inbox for a welcome message.',
          style: ETextStyles.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ESpacing.lg),
        TextButton(
          onPressed: onReset,
          child: Text(
            'Subscribe another',
            style: ETextStyles.labelSm.copyWith(color: EColors.onSurfaceMuted),
          ),
        ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.type = TextInputType.text,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType type;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: ETextStyles.inputText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ETextStyles.inputLabel,
        hintText: hint,
        hintStyle: ETextStyles.bodySmMuted,
      ),
    );
  }
}
