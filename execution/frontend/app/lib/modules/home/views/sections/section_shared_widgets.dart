import 'package:flutter/material.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../../core/theme/personality_theme.dart';
import '../../../booking/models/service_model.dart';

class SectionWrapper extends StatelessWidget {
  const SectionWrapper({
    super.key,
    required this.child,
    this.useAltBackground = false,
  });

  final Widget child;
  final bool useAltBackground;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width > ESpacing.desktopBreak
        ? ESpacing.pagePaddingHDesktop
        : ESpacing.pagePaddingH;

    return Container(
      color: useAltBackground ? EColors.surfaceVariant : EColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: ESpacing.sectionGap,
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.overline,
    this.subtitle,
    this.textAlign = TextAlign.left,
  });

  final String title;
  final String? overline;
  final String? subtitle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (overline != null && overline!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: ESpacing.xs),
            child: Text(
              overline!.toUpperCase(),
              style: ETextStyles.overline,
              textAlign: textAlign,
            ),
          ),
        Text(title, style: ETextStyles.displayMd, textAlign: textAlign),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: ESpacing.sm),
          Text(subtitle!, style: ETextStyles.bodyMuted, textAlign: textAlign),
        ],
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.pt,
    required this.onTap,
  });

  final ServiceModel service;
  final PersonalityTheme pt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (service.imageUrl != null)
              SizedBox(
                height: 140,
                width: double.infinity,
                child: Image.network(service.imageUrl!, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(ESpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name, style: ETextStyles.h3),
                  const SizedBox(height: ESpacing.xs),
                  Text(
                    '${service.formattedDuration} · ${service.formattedPrice}',
                    style: ETextStyles.bodySm.copyWith(color: EColors.primary),
                  ),
                  if (service.description.isNotEmpty) ...[
                    const SizedBox(height: ESpacing.xs),
                    Text(
                      service.description,
                      style: ETextStyles.bodySmMuted,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
