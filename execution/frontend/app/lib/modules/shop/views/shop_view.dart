import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/shop_controller.dart';
import '../models/product_model.dart';

class ShopView extends GetView<ShopController> {
  const ShopView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        elevation: 0,
        title: Text('Shop', style: ETextStyles.h2),
        actions: [CartBadge(controller: controller)],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(children: [
          _CategoryFilter(controller: controller),
          Expanded(
            child: controller.products.isEmpty
                ? Center(
                    child: Text('No products available',
                        style: ETextStyles.bodyMd
                            .copyWith(color: EColors.onSurfaceMuted)),
                  )
                : _ProductGrid(controller: controller),
          ),
        ]);
      }),
    );
  }
}

// ── Cart badge icon ───────────────────────────────────────────────────────────

class CartBadge extends StatelessWidget {
  const CartBadge({super.key, required this.controller});
  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => Get.toNamed(ERoutes.shopCart),
            ),
            if (controller.cartCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: CircleAvatar(
                  radius: 9,
                  backgroundColor: EColors.primary,
                  child: Text(
                    '${controller.cartCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
          ],
        ));
  }
}

// ── Category filter chips ─────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.controller});
  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: ESpacing.md, vertical: ESpacing.xs),
        children: [
          Obx(() => _Chip(
                label: 'All',
                selected: controller.selectedCategory.value == null,
                onTap: () => controller.setCategory(null),
              )),
          ...controller.categories.map((c) => Obx(() => _Chip(
                label: c['name'] as String,
                selected: controller.selectedCategory.value == c['id'],
                onTap: () => controller.setCategory(c['id'] as String),
              ))),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: ESpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: EColors.primaryLight,
        checkmarkColor: EColors.primary,
        labelStyle: ETextStyles.bodyMd.copyWith(
          color: selected ? EColors.primary : EColors.onSurface,
        ),
      ),
    );
  }
}

// ── Product grid ──────────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.controller});
  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    final cols = MediaQuery.sizeOf(context).width > ESpacing.mobileBreak ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(ESpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: ESpacing.md,
        mainAxisSpacing: ESpacing.md,
        childAspectRatio: 0.7,
      ),
      itemCount: controller.products.length,
      itemBuilder: (_, i) =>
          _ProductCard(product: controller.products[i], controller: controller),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.controller});
  final ProductModel product;
  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Get.toNamed(ERoutes.shopProduct, arguments: product),
      child: Container(
        decoration: BoxDecoration(
          color: EColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: product.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.thumbnailUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorWidget: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(ESpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: ETextStyles.bodyMd,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(product.formattedPrice,
                        style: ETextStyles.price
                            .copyWith(color: EColors.primary)),
                    if (product.formattedCompareAt != null) ...[
                      const SizedBox(width: ESpacing.xs),
                      Text(
                        product.formattedCompareAt!,
                        style: ETextStyles.bodyMd.copyWith(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: EColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ]),
                  if (!product.inStock)
                    Text('Out of stock',
                        style: ETextStyles.bodyMd
                            .copyWith(fontSize: 11, color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: EColors.surfaceVariant,
        child: Icon(Icons.image_outlined,
            color: EColors.onSurfaceMuted, size: 48),
      );
}
