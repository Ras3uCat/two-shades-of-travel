import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/blog_controller.dart';
import '../models/blog_post_model.dart';

class BlogListView extends GetView<BlogController> {
  const BlogListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.posts.isEmpty) {
          return Center(
            child: Text('No posts yet.', style: ETextStyles.bodyMd),
          );
        }
        return LayoutBuilder(
          builder: (_, constraints) {
            final cols = constraints.maxWidth > 800 ? 3 : constraints.maxWidth > 500 ? 2 : 1;
            return GridView.builder(
              padding: const EdgeInsets.all(ESpacing.lg),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: ESpacing.md,
                mainAxisSpacing: ESpacing.md,
                childAspectRatio: 0.85,
              ),
              itemCount: controller.posts.length,
              itemBuilder: (_, i) =>
                  _BlogCard(post: controller.posts[i]),
            );
          },
        );
      }),
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.post});
  final BlogPostModel post;

  @override
  Widget build(BuildContext context) {
    final dateStr = post.publishedAt != null
        ? DateFormat('MMM d, yyyy').format(post.publishedAt!.toLocal())
        : '';
    final preview = post.body.length > 120
        ? '${post.body.substring(0, 120).trim()}…'
        : post.body;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Get.toNamed('/blog/${post.slug}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.coverUrl != null)
              Expanded(
                flex: 3,
                child: CachedNetworkImage(
                  imageUrl: post.coverUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(color: EColors.surfaceVariant),
                  errorWidget: (_, _, _) =>
                      Container(color: EColors.surfaceVariant),
                ),
              )
            else
              Expanded(
                flex: 3,
                child: Container(
                  color: EColors.surfaceVariant,
                  child: Center(
                    child: Icon(Icons.article_outlined,
                        size: 40, color: EColors.onSurfaceMuted),
                  ),
                ),
              ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(ESpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dateStr.isNotEmpty)
                      Text(dateStr,
                          style: ETextStyles.bodyMd.copyWith(
                              color: EColors.onSurfaceMuted, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(post.title,
                        style: ETextStyles.h4,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: ESpacing.xs),
                    Text(preview,
                        style: ETextStyles.bodyMd,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
