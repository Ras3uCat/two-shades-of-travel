import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../controllers/shop_controller.dart';
import '../models/cart_item_model.dart';

class CartView extends GetView<ShopController> {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        elevation: 0,
        title: Text('Cart', style: ETextStyles.h2),
      ),
      body: Obx(() {
        if (controller.cartItems.isEmpty) {
          return _EmptyCart();
        }
        return Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(ESpacing.md),
              children: [
                ...controller.cartItems.map(
                  (item) => _CartItemTile(item: item, controller: controller),
                ),
                const SizedBox(height: ESpacing.lg),
                _DiscountRow(controller: controller),
                const Divider(height: ESpacing.xl),
                _SummaryRow(label: 'Subtotal', value: controller.formattedSubtotal),
                if (controller.discountCents > 0)
                  _SummaryRow(
                    label: 'Discount (${controller.discountCode.value})',
                    value: '−${controller.formattedDiscount}',
                    valueColor: Colors.green,
                  ),
                const SizedBox(height: ESpacing.xs),
                _SummaryRow(
                  label: 'Total',
                  value: controller.formattedTotal,
                  bold: true,
                ),
              ],
            ),
          ),
          _CheckoutBar(controller: controller),
        ]);
      }),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.controller});
  final CartItemModel item;
  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESpacing.sm),
      child: Row(children: [
        // Thumbnail
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: EColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: item.product.thumbnailUrl != null
              ? Image.network(item.product.thumbnailUrl!, fit: BoxFit.cover)
              : Icon(Icons.image_outlined, color: EColors.onSurfaceMuted),
        ),
        const SizedBox(width: ESpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.name,
                style: ETextStyles.bodyMd, maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Text(item.product.formattedPrice,
                style: ETextStyles.bodyMd.copyWith(color: EColors.primary)),
          ]),
        ),
        // Qty controls
        Row(children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () =>
                controller.setQuantity(item.product.id, item.quantity - 1),
          ),
          Text('${item.quantity}', style: ETextStyles.bodyMd),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () =>
                controller.setQuantity(item.product.id, item.quantity + 1),
          ),
        ]),
      ]),
    );
  }
}

class _DiscountRow extends StatefulWidget {
  const _DiscountRow({required this.controller});
  final ShopController controller;

  @override
  State<_DiscountRow> createState() => _DiscountRowState();
}

class _DiscountRowState extends State<_DiscountRow> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final ok = await widget.controller.applyDiscountCode(_codeCtrl.text);
    setState(() => _loading = false);
    if (!ok && context.mounted) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid or expired discount code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (widget.controller.discountPct.value > 0) {
        return Row(children: [
          Expanded(
            child: Text(
              'Code applied: ${widget.controller.discountCode.value} '
              '(${widget.controller.discountPct.value}% off)',
              style: ETextStyles.bodyMd.copyWith(color: Colors.green),
            ),
          ),
          TextButton(
            onPressed: widget.controller.removeDiscount,
            child: const Text('Remove'),
          ),
        ]);
      }
      return Row(children: [
        Expanded(
          child: TextField(
            controller: _codeCtrl,
            decoration: InputDecoration(
              hintText: 'Discount code',
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
        ),
        const SizedBox(width: ESpacing.sm),
        _loading
            ? const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : OutlinedButton(onPressed: _apply, child: const Text('Apply')),
      ]);
    });
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? ETextStyles.h3
        : ETextStyles.bodyMd.copyWith(color: EColors.onSurfaceMuted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(child: Text(label, style: style)),
        Text(value,
            style: style.copyWith(
                color: valueColor ?? (bold ? EColors.primary : null))),
      ]),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.controller});
  final ShopController controller;

  Future<void> _showCheckoutDialog(BuildContext context) async {
    String? prefillEmail;
    String? prefillName;
    try {
      final auth = Get.find<AuthController>();
      prefillEmail = auth.user?.email;
    } catch (_) {}

    final emailCtrl = TextEditingController(text: prefillEmail ?? '');
    final nameCtrl  = TextEditingController(text: prefillName  ?? '');
    final formKey   = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Your details'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            TextFormField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                controller.checkout(emailCtrl.text.trim(), nameCtrl.text.trim());
              }
            },
            child: const Text('Proceed to Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(ESpacing.md),
        child: Obx(() => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(ESpacing.md),
                ),
                onPressed: controller.isCheckingOut.value
                    ? null
                    : () => _showCheckoutDialog(context),
                child: controller.isCheckingOut.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Checkout — ${controller.formattedTotal}'),
              ),
            )),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shopping_cart_outlined,
            size: 64, color: EColors.onSurfaceMuted),
        const SizedBox(height: ESpacing.md),
        Text('Your cart is empty', style: ETextStyles.h3),
        const SizedBox(height: ESpacing.sm),
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Continue shopping'),
        ),
      ]),
    );
  }
}
