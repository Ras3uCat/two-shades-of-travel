import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/blog_post_controller.dart';

class BlogPostView extends GetView<BlogPostController> {
  const BlogPostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: EColors.surface,
        elevation: 0,
        leading: BackButton(color: EColors.onSurface),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.notFound.value || controller.post.value == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Post not found.', style: ETextStyles.bodyMd),
                const SizedBox(height: ESpacing.md),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }
        final post = controller.post.value!;
        final dateStr = post.publishedAt != null
            ? DateFormat('MMMM d, yyyy').format(post.publishedAt!.toLocal())
            : '';
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.coverUrl != null)
                CachedNetworkImage(
                  imageUrl: post.coverUrl!,
                  width: double.infinity,
                  height: 280,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(height: 280, color: EColors.surfaceVariant),
                  errorWidget: (_, _, _) =>
                      Container(height: 280, color: EColors.surfaceVariant),
                ),
              Padding(
                padding: const EdgeInsets.all(ESpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dateStr.isNotEmpty)
                        Text(dateStr,
                            style: ETextStyles.bodyMd.copyWith(
                                color: EColors.onSurfaceMuted,
                                fontSize: 13)),
                      const SizedBox(height: ESpacing.sm),
                      Text(post.title, style: ETextStyles.h2),
                      const SizedBox(height: ESpacing.lg),
                      _BodyText(body: post.body),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Renders body text as a series of paragraphs (split on blank lines).
class _BodyText extends StatelessWidget {
  const _BodyText({required this.body});
  final String body;

  @override
  Widget build(BuildContext context) {
    final paragraphs = body
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: ESpacing.md),
            child: SelectableText(p, style: ETextStyles.bodyMd),
          ),
      ],
    );
  }
}
