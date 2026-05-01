import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/master_controller.dart';

/// Editable page-content section for BusinessConfigView.
/// Covers hero copy/image, services section labels, and CTA text.
class BusinessContentSection extends StatefulWidget {
  const BusinessContentSection({super.key, required this.controller});
  final MasterController controller;

  @override
  State<BusinessContentSection> createState() =>
      _BusinessContentSectionState();
}

class _BusinessContentSectionState extends State<BusinessContentSection> {
  late final TextEditingController _heroImage;
  late final TextEditingController _heroOverline;
  late final TextEditingController _heroTagline;
  late final TextEditingController _servicesOverline;
  late final TextEditingController _servicesTitle;
  late final TextEditingController _servicesSubtitle;
  late final TextEditingController _ctaTitle;
  late final TextEditingController _ctaButton;

  @override
  void initState() {
    super.initState();
    final c = widget.controller.config;
    _heroImage        = TextEditingController(text: c['hero_image_url']    as String? ?? '');
    _heroOverline     = TextEditingController(text: c['hero_overline']     as String? ?? '');
    _heroTagline      = TextEditingController(text: c['hero_tagline']      as String? ?? '');
    _servicesOverline = TextEditingController(text: c['services_overline'] as String? ?? 'What We Offer');
    _servicesTitle    = TextEditingController(text: c['services_title']    as String? ?? 'Our Services');
    _servicesSubtitle = TextEditingController(text: c['services_subtitle'] as String? ?? '');
    _ctaTitle         = TextEditingController(text: c['cta_title']         as String? ?? 'Ready to Get Started?');
    _ctaButton        = TextEditingController(text: c['cta_button_label']  as String? ?? 'Book Your Appointment');
  }

  @override
  void dispose() {
    for (final c in [
      _heroImage, _heroOverline, _heroTagline,
      _servicesOverline, _servicesTitle, _servicesSubtitle,
      _ctaTitle, _ctaButton,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Page Content', style: ETextStyles.h3),
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
        _label('Hero'),
        const SizedBox(height: ESpacing.sm),
        _TF(ctrl: _heroImage, label: 'Hero image URL'),
        const SizedBox(height: ESpacing.sm),
        Row(children: [
          Expanded(child: _TF(ctrl: _heroOverline, label: 'Overline')),
          const SizedBox(width: ESpacing.md),
          Expanded(child: _TF(ctrl: _heroTagline,  label: 'Tagline')),
        ]),
        const SizedBox(height: ESpacing.lg),
        _label('Services Section'),
        const SizedBox(height: ESpacing.sm),
        Row(children: [
          Expanded(child: _TF(ctrl: _servicesOverline, label: 'Overline')),
          const SizedBox(width: ESpacing.md),
          Expanded(child: _TF(ctrl: _servicesTitle, label: 'Title')),
        ]),
        const SizedBox(height: ESpacing.sm),
        _TF(ctrl: _servicesSubtitle, label: 'Subtitle (optional)'),
        const SizedBox(height: ESpacing.lg),
        _label('CTA Section'),
        const SizedBox(height: ESpacing.sm),
        Row(children: [
          Expanded(child: _TF(ctrl: _ctaTitle,  label: 'Heading')),
          const SizedBox(width: ESpacing.md),
          Expanded(child: _TF(ctrl: _ctaButton, label: 'Button label')),
        ]),
      ],
    );
  }

  Widget _label(String text) => Text(text,
      style: ETextStyles.label.copyWith(color: EColors.onSurfaceMuted));

  Future<void> _save() async {
    final img = _heroImage.text.trim();
    await widget.controller.saveConfig({
      'hero_image_url':    img.isEmpty ? null : img,
      'hero_overline':     _heroOverline.text.trim(),
      'hero_tagline':      _heroTagline.text.trim(),
      'services_overline': _servicesOverline.text.trim(),
      'services_title':    _servicesTitle.text.trim(),
      'services_subtitle': _servicesSubtitle.text.trim(),
      'cta_title':         _ctaTitle.text.trim(),
      'cta_button_label':  _ctaButton.text.trim(),
    });
    Get.snackbar('Saved', 'Page content updated.',
        backgroundColor: EColors.primary.withValues(alpha: 0.9),
        colorText: EColors.secondary);
  }
}

class _TF extends StatelessWidget {
  const _TF({required this.ctrl, required this.label});
  final TextEditingController ctrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: ETextStyles.inputText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ETextStyles.inputLabel,
      ),
    );
  }
}
