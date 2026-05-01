import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/gallery_controller.dart';
import '../models/gallery_photo_model.dart';

class GallerySection extends GetView<GalleryController> {
  const GallerySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.photos.isEmpty) {
        return const SizedBox.shrink();
      }
      return LayoutBuilder(
        builder: (_, constraints) {
          final cols = constraints.maxWidth > 900
              ? 4
              : constraints.maxWidth > 600
                  ? 3
                  : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: controller.photos.length,
            itemBuilder: (ctx, i) {
              final photo = controller.photos[i];
              return GestureDetector(
                onTap: () => _showLightbox(ctx, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: photo.publicUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: EColors.surfaceVariant),
                    errorWidget: (_, _, _) => Container(
                      color: EColors.surfaceVariant,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    });
  }

  void _showLightbox(BuildContext context, int initialIndex) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _LightboxDialog(
        photos: controller.photos,
        initialIndex: initialIndex,
      ),
    );
  }
}

// ── Lightbox ──────────────────────────────────────────────────────────────────

class _LightboxDialog extends StatefulWidget {
  const _LightboxDialog({
    required this.photos,
    required this.initialIndex,
  });
  final List<GalleryPhotoModel> photos;
  final int initialIndex;

  @override
  State<_LightboxDialog> createState() => _LightboxDialogState();
}

class _LightboxDialogState extends State<_LightboxDialog> {
  late int _current;
  late PageController _page;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _page    = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_current];
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Tap background to close
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),

          // Swipeable photo viewer
          Center(
            child: PageView.builder(
              controller: _page,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: widget.photos[i].publicUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, _) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.broken_image, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Caption
          if (photo.caption != null)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    photo.caption!,
                    style: ETextStyles.bodySm.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),

          // Prev arrow
          if (widget.photos.length > 1 && _current > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white, size: 40),
                  onPressed: () => _page.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.ease,
                  ),
                ),
              ),
            ),

          // Next arrow
          if (widget.photos.length > 1 &&
              _current < widget.photos.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: Colors.white, size: 40),
                  onPressed: () => _page.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.ease,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
