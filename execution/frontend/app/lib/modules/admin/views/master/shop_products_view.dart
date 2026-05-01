import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../../modules/shop/controllers/shop_admin_controller.dart';
import '../../../../modules/shop/models/product_model.dart';
import '../admin_shell.dart';

class ShopProductsView extends GetView<ShopAdminController> {
  const ShopProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminShopProducts,
      isMaster: true,
      child: Scaffold(
        backgroundColor: EColors.surface,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showProductDialog(context, null),
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
          backgroundColor: EColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(ESpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: ESpacing.md),
                child: Text('Products (${controller.products.length})',
                    style: ETextStyles.h2),
              ),
              ...controller.products.map(
                (p) => _ProductTile(
                  product: p,
                  onEdit: () => _showProductDialog(context, p),
                  onDelete: () => _confirmDelete(context, p),
                ),
              ),
              const SizedBox(height: 80), // FAB clearance
            ],
          );
        }),
      ),
    );
  }

  Future<void> _showProductDialog(BuildContext context, ProductModel? existing) async {
    final nameCtrl   = TextEditingController(text: existing?.name ?? '');
    final descCtrl   = TextEditingController(text: existing?.description ?? '');
    final priceCtrl  = TextEditingController(
        text: existing != null ? (existing.priceCents / 100).toStringAsFixed(2) : '');
    final compareCtrl = TextEditingController(
        text: existing?.compareAtPriceCents != null
            ? (existing!.compareAtPriceCents! / 100).toStringAsFixed(2)
            : '');
    final imagesCtrl  = TextEditingController(text: existing?.images.join(', ') ?? '');
    final tagsCtrl    = TextEditingController(text: existing?.tags.join(', ') ?? '');
    final invCtrl     = TextEditingController(
        text: existing?.inventoryCount?.toString() ?? '');
    final activeObs   = (existing?.isActive ?? true).obs;
    final formKey     = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Product' : 'Edit Product'),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: 'Price *'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          double.tryParse(v ?? '') == null ? 'Enter a number' : null,
                    ),
                  ),
                  const SizedBox(width: ESpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: compareCtrl,
                      decoration: const InputDecoration(labelText: 'Compare-at price'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ]),
                TextFormField(
                  controller: invCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Inventory (blank = unlimited)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: imagesCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Image URLs (comma-separated)'),
                ),
                TextFormField(
                  controller: tagsCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Tags (comma-separated)'),
                ),
                const SizedBox(height: ESpacing.sm),
                Obx(() => SwitchListTile(
                      title: const Text('Active'),
                      value: activeObs.value,
                      onChanged: (v) => activeObs.value = v,
                      activeTrackColor: EColors.primary,
                      contentPadding: EdgeInsets.zero,
                    )),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final data = {
                'name':        nameCtrl.text.trim(),
                'description': descCtrl.text.trim().isNotEmpty
                    ? descCtrl.text.trim()
                    : null,
                'price_cents': (double.parse(priceCtrl.text) * 100).round(),
                'compare_at_price_cents': compareCtrl.text.trim().isNotEmpty
                    ? (double.parse(compareCtrl.text) * 100).round()
                    : null,
                'inventory_count': invCtrl.text.trim().isNotEmpty
                    ? int.parse(invCtrl.text.trim())
                    : null,
                'images': imagesCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
                'tags': tagsCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList(),
                'is_active': activeObs.value,
              };
              Navigator.pop(context);
              if (existing == null) {
                controller.createProduct(data);
              } else {
                controller.updateProduct(existing.id, data);
              }
            },
            child: Text(existing == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel p) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Delete "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              controller.deleteProduct(p.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: ESpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: product.isActive
              ? EColors.primaryLight
              : EColors.surfaceVariant,
          child: Icon(
            product.isActive ? Icons.inventory_2_outlined : Icons.hide_source,
            color: product.isActive ? EColors.primary : EColors.onSurfaceMuted,
            size: 20,
          ),
        ),
        title: Text(product.name, style: ETextStyles.bodyMd),
        subtitle: Text(
          '${product.formattedPrice}'
          '${!product.isActive ? ' · Hidden' : ''}'
          '${product.inventoryCount != null ? ' · Stock: ${product.inventoryCount}' : ''}',
          style: ETextStyles.bodyMd.copyWith(color: EColors.onSurfaceMuted),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit),
          IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete),
        ]),
      ),
    );
  }
}
