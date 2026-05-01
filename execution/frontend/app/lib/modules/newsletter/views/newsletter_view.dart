import 'package:flutter/material.dart';
import '../../../core/config/app_env.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/seo_wrapper.dart';
import '../widgets/newsletter_form.dart';

class NewsletterView extends StatelessWidget {
  const NewsletterView({super.key});

  @override
  Widget build(BuildContext context) {
    return SeoWrapper(
      title: 'Newsletter',
      description: 'Subscribe to ${AppEnv.clientName} for exclusive offers and news.',
      child: AppShell(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _Hero(),
              _FormSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: EColors.secondary,
      padding: const EdgeInsets.symmetric(
        horizontal: ESpacing.pagePaddingH,
        vertical: ESpacing.sectionGap,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STAY IN THE LOOP',
                style: ETextStyles.overline.copyWith(color: EColors.primary),
              ),
              const SizedBox(height: ESpacing.sm),
              Text(
                'Exclusive offers.\nNew arrivals. First looks.',
                style: ETextStyles.h1.copyWith(color: EColors.white),
              ),
              const SizedBox(height: ESpacing.md),
              Text(
                'Join the ${AppEnv.clientName} community. No spam — '
                'just the things worth knowing about.',
                style: ETextStyles.body.copyWith(
                    color: EColors.white.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ESpacing.pagePaddingH,
        vertical: ESpacing.sectionGap,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const NewsletterFormWidget(),
        ),
      ),
    );
  }
}
