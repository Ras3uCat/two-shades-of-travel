import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../gallery/models/gallery_photo_model.dart';
import '../../controllers/master_controller.dart';
import '../admin_shell.dart';

/// GalleryManagerView — admin CRUD for gallery photos.
///
/// Upload flow: use the Supabase Storage dashboard to upload an image to the
/// `gallery` bucket, then register the file path + caption here.
class GalleryManagerView extends GetView<MasterController> {
  const GalleryManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      isMaster: true,
      currentRoute: ERoutes.adminGallery,
      child: Padding(
        padding: const EdgeInsets.all(ESpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onAdd: () => _showAddDialog(context)),
            const SizedBox(height: ESpacing.md),
            Expanded(
              child: Obx(() {
                final photos = controller.galleryPhotos;
                if (photos.isEmpty) {
                  return Center(
                    child: Text(
                      'No photos yet.\n'
                      'Upload an image to the Supabase Storage "gallery" bucket,\n'
                      'then tap "Add Photo" to register it.',
                      style: ETextStyles.bodyMd,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: ESpacing.sm,
                    mainAxisSpacing: ESpacing.sm,
                  ),
                  itemCount: photos.length,
                  itemBuilder: (_, i) => _PhotoTile(
                    photo: photos[i],
                    onEdit: () => _showEditDialog(context, photos[i]),
                    onDelete: () => _confirmDelete(context, photos[i]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final pathCtrl    = TextEditingController();
    final captionCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload the image to the Supabase Storage "gallery" bucket first,\n'
              'then enter the file path below.',
              style: ETextStyles.bodyMd
                  .copyWith(color: EColors.onSurfaceMuted, fontSize: 12),
            ),
            const SizedBox(height: ESpacing.md),
            TextField(
              controller: pathCtrl,
              decoration: const InputDecoration(
                labelText: 'Storage path *',
                hintText: 'e.g. studio-interior.jpg',
              ),
            ),
            const SizedBox(height: ESpacing.sm),
            TextField(
              controller: captionCtrl,
              decoration: const InputDecoration(
                labelText: 'Caption (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final path = pathCtrl.text.trim();
              if (path.isEmpty) return;
              Navigator.pop(ctx);
              controller.addGalleryPhoto(
                storagePath: path,
                caption: captionCtrl.text.trim().isEmpty
                    ? null
                    : captionCtrl.text.trim(),
                displayOrder: controller.galleryPhotos.length,
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, GalleryPhotoModel photo) {
    final captionCtrl = TextEditingController(text: photo.caption ?? '');
    bool isActive = photo.isActive;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: captionCtrl,
                decoration: const InputDecoration(labelText: 'Caption'),
              ),
              const SizedBox(height: ESpacing.md),
              SwitchListTile(
                title: const Text('Visible on site'),
                value: isActive,
                activeTrackColor: EColors.primary,
                onChanged: (v) => setState(() => isActive = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                controller.updateGalleryPhoto(photo.id, {
                  'caption': captionCtrl.text.trim().isEmpty
                      ? null
                      : captionCtrl.text.trim(),
                  'is_active': isActive,
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, GalleryPhotoModel photo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text(
            'This removes the DB record. The file in Storage is also deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteGalleryPhoto(photo.id, photo.storagePath);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Gallery', style: ETextStyles.h3),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
          label: const Text('Add Photo'),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.onEdit,
    required this.onDelete,
  });
  final GalleryPhotoModel photo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
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
        if (!photo.isActive)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Colors.black45,
              child: const Center(
                child: Text('Hidden',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ),
          ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionBtn(icon: Icons.edit_outlined, onTap: onEdit),
              const SizedBox(width: 4),
              _ActionBtn(
                  icon: Icons.delete_outline,
                  onTap: onDelete,
                  color: Colors.redAccent),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color ?? Colors.white),
        ),
      ),
    );
  }
}
