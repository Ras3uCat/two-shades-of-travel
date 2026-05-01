import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/shop_controller.dart';

class OrderConfirmationView extends GetView<ShopController> {
  const OrderConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    final status  = Get.parameters['status'];
    final orderId = Get.parameters['order_id'];
    final success = status == 'success';

    // Clear cart on successful payment
    if (success) controller.clearCart();

    return Scaffold(
      backgroundColor: EColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(ESpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  success ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 80,
                  color: success ? Colors.green : Colors.red,
                ),
                const SizedBox(height: ESpacing.lg),
                Text(
                  success ? 'Order Confirmed!' : 'Payment Cancelled',
                  style: ETextStyles.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ESpacing.sm),
                Text(
                  success
                      ? "You'll receive a confirmation email shortly."
                      : 'Your cart has been saved. You can try again when ready.',
                  style: ETextStyles.bodyMd
                      .copyWith(color: EColors.onSurfaceMuted),
                  textAlign: TextAlign.center,
                ),
                if (success && orderId != null) ...[
                  const SizedBox(height: ESpacing.sm),
                  Text(
                    'Order #${orderId.substring(0, 8).toUpperCase()}',
                    style: ETextStyles.bodyMd
                        .copyWith(color: EColors.onSurfaceMuted),
                  ),
                ],
                const SizedBox(height: ESpacing.xl),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: ESpacing.xl, vertical: ESpacing.md),
                  ),
                  onPressed: () => Get.offAllNamed(ERoutes.shop),
                  child: const Text('Continue Shopping'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
