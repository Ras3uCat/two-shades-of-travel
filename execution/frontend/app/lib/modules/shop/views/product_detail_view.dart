import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/shop_controller.dart';
import '../models/product_model.dart';
import 'shop_view.dart' show CartBadge;

class ProductDetailView extends GetView<ShopController> {
  const ProductDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final product = Get.arguments as ProductModel?;
    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Product not found')),
      );
    }

    final qty = 1.obs;

    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        elevation: 0,
        title: Text(product.name, style: ETextStyles.h3),
        actions: [CartBadge(controller: controller)],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image carousel ──────────────────────────────────────────────
            if (product.images.isNotEmpty)
              SizedBox(
                height: 320,
                child: PageView.builder(
                  itemCount: product.images.length,
                  itemBuilder: (_, i) => CachedNetworkImage(
                    imageUrl: product.images[i],
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _imgPlaceholder(),
                  ),
                ),
              )
            else
              SizedBox(height: 240, child: _imgPlaceholder()),

            // ── Details ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(ESpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Row(children: [
                    Text(product.formattedPrice,
                        style: ETextStyles.h2.copyWith(color: EColors.primary)),
                    if (product.formattedCompareAt != null) ...[
                      const SizedBox(width: ESpacing.sm),
                      Text(
                        product.formattedCompareAt!,
                        style: ETextStyles.bodyMd.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: EColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: ESpacing.md),

                  // Out of stock badge
                  if (!product.inStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: ESpacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Out of stock',
                          style: ETextStyles.bodyMd
                              .copyWith(color: Colors.red)),
                    ),

                  // Description
                  if (product.description != null) ...[
                    const SizedBox(height: ESpacing.md),
                    Text(product.description!, style: ETextStyles.bodyMd),
                  ],

                  // Tags
                  if (product.tags.isNotEmpty) ...[
                    const SizedBox(height: ESpacing.md),
                    Wrap(
                      spacing: ESpacing.xs,
                      children: product.tags
                          .map((t) => Chip(
                                label: Text(t, style: ETextStyles.bodyMd),
                                backgroundColor: EColors.surfaceVariant,
                              ))
                          .toList(),
                    ),
                  ],

                  // Quantity + add to cart
                  if (product.inStock) ...[
                    const SizedBox(height: ESpacing.lg),
                    Text('Quantity', style: ETextStyles.h3),
                    const SizedBox(height: ESpacing.sm),
                    Obx(() => Row(children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed:
                                qty.value > 1 ? () => qty.value-- : null,
                          ),
                          Text('${qty.value}', style: ETextStyles.h3),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (product.inventoryCount == null ||
                                  qty.value < product.inventoryCount!) {
                                qty.value++;
                              }
                            },
                          ),
                        ])),
                    const SizedBox(height: ESpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add to Cart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(ESpacing.md),
                        ),
                        onPressed: () {
                          controller.addToCart(product, qty: qty.value);
                          Get.snackbar(
                            'Added to cart',
                            '${product.name} × ${qty.value}',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: ESpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: EColors.surfaceVariant,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined,
            color: EColors.onSurfaceMuted, size: 80),
      );
}
