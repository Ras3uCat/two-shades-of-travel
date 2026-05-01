import 'package:flutter/material.dart';

import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../widgets/gallery_section.dart';

class GalleryView extends StatelessWidget {
  const GalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ESpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gallery', style: ETextStyles.h2),
            const SizedBox(height: ESpacing.lg),
            const GallerySection(),
            const SizedBox(height: ESpacing.xxl),
          ],
        ),
      ),
    );
  }
}
