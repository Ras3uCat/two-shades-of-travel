import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../modules/_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/e_colors.dart';
import '../../core/theme/e_spacing.dart';
import '../../core/theme/e_text_styles.dart';

// ── Module ────────────────────────────────────────────────────────────────────

class GiftModule implements AppModule {
  @override
  String get moduleId => 'gift';

  @override
  NavItem? get navItem => null; // no public nav — accessed via direct link or CTA

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.gift,
          page: () => const GiftView(),
          binding: GiftBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.giftSuccess,
          page: () => const GiftSuccessView(),
          transition: Transition.fadeIn,
        ),
      ];

  @override
  Bindings? get binding => null;
}

// ── Binding ───────────────────────────────────────────────────────────────────

class GiftBinding extends Bindings {
  @override
  void dependencies() { Get.put(GiftController()); }
}

// ── Controller ────────────────────────────────────────────────────────────────

class GiftController extends GetxController {
  final selectedAmountCents = 2500.obs; // default £25
  final customAmount        = ''.obs;
  final purchaserEmail      = ''.obs;
  final recipientEmail      = ''.obs;
  final message             = ''.obs;
  final isLoading           = false.obs;
  final error               = RxnString();

  static const presets = [2500, 5000, 10000]; // £25 / £50 / £100

  int get effectiveAmountCents {
    final custom = int.tryParse(customAmount.value);
    if (custom != null && custom > 0) return custom * 100;
    return selectedAmountCents.value;
  }

  Future<void> launchCheckout() async {
    error.value = null;

    if (purchaserEmail.value.trim().isEmpty ||
        recipientEmail.value.trim().isEmpty) {
      error.value = 'Please fill in both email addresses.';
      return;
    }

    isLoading.value = true;
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'create-gift-checkout',
        body: {
          'amount_cents':        effectiveAmountCents,
          'purchased_by_email':  purchaserEmail.value.trim(),
          'recipient_email':     recipientEmail.value.trim(),
          'message':             message.value.trim(),
        },
      );
      final url = res.data?['url'] as String?;
      if (url == null || url.isEmpty) throw Exception('No checkout URL returned.');
      await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
    } catch (e) {
      error.value = 'Could not start checkout. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}

// ── Gift View ─────────────────────────────────────────────────────────────────

class GiftView extends GetView<GiftController> {
  const GiftView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        title: Text('Gift Voucher', style: ETextStyles.h3),
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(ESpacing.xl),
            children: [
              Text('Give the gift of great service.',
                  style: ETextStyles.h2),
              const SizedBox(height: ESpacing.xs),
              Text('Sent instantly by email to the recipient.',
                  style: ETextStyles.bodyMuted),
              const SizedBox(height: ESpacing.xl),

              // Amount presets
              Text('Select amount', style: ETextStyles.label),
              const SizedBox(height: ESpacing.sm),
              Obx(() => Wrap(
                    spacing: ESpacing.sm,
                    children: GiftController.presets.map((cents) {
                      final selected =
                          controller.selectedAmountCents.value == cents &&
                          controller.customAmount.value.isEmpty;
                      return ChoiceChip(
                        label: Text('£${cents ~/ 100}',
                            style: ETextStyles.label.copyWith(
                              color: selected
                                  ? EColors.secondary
                                  : EColors.onSurface,
                            )),
                        selected: selected,
                        selectedColor: EColors.primary,
                        backgroundColor: EColors.surfaceVariant,
                        side: BorderSide(color: EColors.divider, width: 0.5),
                        shape: const RoundedRectangleBorder(),
                        onSelected: (_) {
                          controller.selectedAmountCents.value = cents;
                          controller.customAmount.value = '';
                        },
                      );
                    }).toList(),
                  )),
              const SizedBox(height: ESpacing.md),

              // Custom amount
              TextField(
                keyboardType: TextInputType.number,
                style: ETextStyles.inputText,
                decoration: InputDecoration(
                  labelText: 'Or enter custom amount (£)',
                  labelStyle: ETextStyles.inputLabel,
                  prefixText: '£ ',
                ),
                onChanged: controller.customAmount.call,
              ),
              const SizedBox(height: ESpacing.lg),

              // Purchaser email
              TextField(
                keyboardType: TextInputType.emailAddress,
                style: ETextStyles.inputText,
                decoration: InputDecoration(
                  labelText: 'Your email',
                  labelStyle: ETextStyles.inputLabel,
                ),
                onChanged: controller.purchaserEmail.call,
              ),
              const SizedBox(height: ESpacing.md),

              // Recipient email
              TextField(
                keyboardType: TextInputType.emailAddress,
                style: ETextStyles.inputText,
                decoration: InputDecoration(
                  labelText: "Recipient's email",
                  labelStyle: ETextStyles.inputLabel,
                ),
                onChanged: controller.recipientEmail.call,
              ),
              const SizedBox(height: ESpacing.md),

              // Optional message
              TextField(
                maxLines: 3,
                style: ETextStyles.inputText,
                decoration: InputDecoration(
                  labelText: 'Personal message (optional)',
                  labelStyle: ETextStyles.inputLabel,
                  alignLabelWithHint: true,
                ),
                onChanged: controller.message.call,
              ),
              const SizedBox(height: ESpacing.xl),

              // Error
              Obx(() => controller.error.value != null
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: ESpacing.md),
                      child: Text(controller.error.value!,
                          style: ETextStyles.bodySm
                              .copyWith(color: EColors.error)),
                    )
                  : const SizedBox.shrink()),

              // CTA
              Obx(() => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.launchCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EColors.primary,
                        foregroundColor: EColors.secondary,
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(
                            vertical: ESpacing.md),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : Text('Buy Gift Voucher',
                              style: ETextStyles.button),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Gift Success View ─────────────────────────────────────────────────────────

class GiftSuccessView extends StatelessWidget {
  const GiftSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(ESpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard_outlined,
                    size: 64, color: EColors.primary),
                const SizedBox(height: ESpacing.lg),
                Text('Gift voucher sent!', style: ETextStyles.h2),
                const SizedBox(height: ESpacing.sm),
                Text(
                  'The recipient will receive their voucher code by email shortly. '
                  'Thank you for your purchase.',
                  style: ETextStyles.bodyMuted,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ESpacing.xl),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed(ERoutes.home),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColors.primary,
                    foregroundColor: EColors.secondary,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: ESpacing.xl, vertical: ESpacing.md),
                  ),
                  child: Text('Back to home', style: ETextStyles.button),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
