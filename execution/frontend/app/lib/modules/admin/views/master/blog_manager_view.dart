import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../blog/models/blog_post_model.dart';
import '../../../../core/utils/slugify.dart';
import '../../controllers/master_controller.dart';
import '../admin_shell.dart';

class BlogManagerView extends GetView<MasterController> {
  const BlogManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      isMaster: true,
      currentRoute: ERoutes.adminBlog,
      child: Padding(
        padding: const EdgeInsets.all(ESpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Blog Posts', style: ETextStyles.h3),
                ElevatedButton.icon(
                  onPressed: () => _openEditor(context, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Post'),
                ),
              ],
            ),
            const SizedBox(height: ESpacing.lg),
            Expanded(
              child: Obx(() {
                final posts = controller.blogPosts;
                if (posts.isEmpty) {
                  return Center(
                    child: Text('No posts yet.', style: ETextStyles.bodyMd),
                  );
                }
                return ListView.separated(
                  itemCount: posts.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (_, i) => _PostTile(
                    post: posts[i],
                    onEdit: () => _openEditor(context, posts[i]),
                    onDelete: () => _confirmDelete(context, posts[i]),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, BlogPostModel? existing) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _PostEditorDialog(
        existing: existing,
        onSave: (data) {
          if (existing == null) {
            controller.createBlogPost(data);
          } else {
            controller.updateBlogPost(existing.id, data);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, BlogPostModel post) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: Text('Delete "${post.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteBlogPost(post.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Post list tile ────────────────────────────────────────────────────────────

class _PostTile extends StatelessWidget {
  const _PostTile({
    required this.post,
    required this.onEdit,
    required this.onDelete,
  });
  final BlogPostModel post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateStr = post.publishedAt != null
        ? DateFormat('MMM d, yyyy').format(post.publishedAt!.toLocal())
        : 'Draft';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: ESpacing.xs),
      leading: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ESpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: post.isPublished
              ? EColors.primaryLight
              : EColors.surfaceVariant,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          post.isPublished ? 'Live' : 'Draft',
          style: ETextStyles.overline.copyWith(
            color: post.isPublished ? EColors.primary : EColors.onSurfaceMuted,
          ),
        ),
      ),
      title: Text(post.title, style: ETextStyles.bodyMd),
      subtitle: Text(
        dateStr,
        style: ETextStyles.bodyMd.copyWith(
          color: EColors.onSurfaceMuted,
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: EColors.onSurfaceMuted,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.redAccent,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Editor dialog ─────────────────────────────────────────────────────────────

class _PostEditorDialog extends StatefulWidget {
  const _PostEditorDialog({required this.existing, required this.onSave});
  final BlogPostModel? existing;
  final void Function(Map<String, dynamic>) onSave;

  @override
  State<_PostEditorDialog> createState() => _PostEditorDialogState();
}

class _PostEditorDialogState extends State<_PostEditorDialog> {
  late final TextEditingController _title;
  late final TextEditingController _slug;
  late final TextEditingController _cover;
  late final TextEditingController _body;
  bool _published = false;
  bool _slugEdited = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _slug = TextEditingController(text: e?.slug ?? '');
    _cover = TextEditingController(text: e?.coverUrl ?? '');
    _body = TextEditingController(text: e?.body ?? '');
    _published = e?.isPublished ?? false;
    _slugEdited = e != null; // existing slug: don't auto-overwrite

    _title.addListener(() {
      if (!_slugEdited) {
        _slug.text = slugify(_title.text);
      }
    });
    _slug.addListener(() {
      _slugEdited = true;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _slug.dispose();
    _cover.dispose();
    _body.dispose();
    super.dispose();
  }

  void _save() {
    final slug = _slug.text.trim();
    final title = _title.text.trim();
    if (title.isEmpty || slug.isEmpty) return;
    Navigator.pop(context);
    widget.onSave({
      'slug': slug,
      'title': title,
      'body': _body.text.trim(),
      'cover_url': _cover.text.trim().isEmpty ? null : _cover.text.trim(),
      'is_published': _published,
      if (_published && widget.existing?.isPublished == false)
        'published_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(ESpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isNew ? 'New Post' : 'Edit Post', style: ETextStyles.h3),
              const SizedBox(height: ESpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _title,
                        decoration: const InputDecoration(labelText: 'Title *'),
                      ),
                      const SizedBox(height: ESpacing.sm),
                      TextField(
                        controller: _slug,
                        decoration: const InputDecoration(
                          labelText: 'Slug *',
                          hintText: 'e.g. summer-hair-trends',
                        ),
                      ),
                      const SizedBox(height: ESpacing.sm),
                      TextField(
                        controller: _cover,
                        decoration: const InputDecoration(
                          labelText: 'Cover image URL (optional)',
                          hintText: 'https://...',
                        ),
                      ),
                      const SizedBox(height: ESpacing.sm),
                      TextField(
                        controller: _body,
                        decoration: const InputDecoration(
                          labelText: 'Body',
                          alignLabelWithHint: true,
                          hintText:
                              'Write your post here.\n\nSeparate paragraphs with a blank line.',
                        ),
                        maxLines: null,
                        minLines: 8,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: ESpacing.sm),
                      StatefulBuilder(
                        builder: (_, setState) => SwitchListTile(
                          title: const Text('Published'),
                          value: _published,
                          activeTrackColor: EColors.primary,
                          onChanged: (v) => setState(() => _published = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: ESpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: ESpacing.sm),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(isNew ? 'Create' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
