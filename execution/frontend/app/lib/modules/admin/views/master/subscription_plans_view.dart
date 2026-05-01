import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../views/admin_shell.dart';

class SubscriptionPlansView extends StatefulWidget {
  const SubscriptionPlansView({super.key});

  @override
  State<SubscriptionPlansView> createState() => _SubscriptionPlansViewState();
}

class _SubscriptionPlansViewState extends State<SubscriptionPlansView> {
  SupabaseClient get _db => Supabase.instance.client;
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _db.from('subscription_plans').select().order('display_order');
    if (mounted) setState(() { _plans = (rows as List).cast<Map<String, dynamic>>(); _loading = false; });
  }

  Future<void> _toggleActive(Map<String, dynamic> plan) async {
    final newVal = !(plan['is_active'] as bool? ?? true);
    await _db.from('subscription_plans').update({'is_active': newVal}).eq('id', plan['id'] as String);
    _load();
  }

  Future<void> _delete(String id) async {
    await _db.from('subscription_plans').delete().eq('id', id);
    _load();
  }

  Future<void> _showAddDialog() async {
    final nameCtrl    = TextEditingController();
    final descCtrl    = TextEditingController();
    final priceCtrl   = TextEditingController();
    final stripeCtrl  = TextEditingController();
    final discountCtrl = TextEditingController(text: '0');
    final featuresCtrl = TextEditingController();
    String interval = 'monthly';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: EColors.surface,
          title: Text('Add Subscription Plan', style: ETextStyles.h4),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl,
                decoration: InputDecoration(labelText: 'Name *', labelStyle: ETextStyles.inputLabel)),
              const SizedBox(height: ESpacing.sm),
              TextField(controller: descCtrl,
                decoration: InputDecoration(labelText: 'Description', labelStyle: ETextStyles.inputLabel)),
              const SizedBox(height: ESpacing.sm),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price (dollars) *', labelStyle: ETextStyles.inputLabel)),
              const SizedBox(height: ESpacing.sm),
              InputDecorator(
                decoration: InputDecoration(labelText: 'Interval', labelStyle: ETextStyles.inputLabel),
                child: DropdownButton<String>(
                  value: interval,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: ['monthly', 'quarterly', 'yearly']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) { if (v != null) setDlg(() => interval = v); },
                ),
              ),
              const SizedBox(height: ESpacing.sm),
              TextField(controller: stripeCtrl,
                decoration: InputDecoration(labelText: 'Stripe Price ID (optional)', labelStyle: ETextStyles.inputLabel)),
              const SizedBox(height: ESpacing.sm),
              TextField(controller: discountCtrl, keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Booking Discount %', labelStyle: ETextStyles.inputLabel)),
              const SizedBox(height: ESpacing.sm),
              TextField(controller: featuresCtrl,
                decoration: InputDecoration(
                  labelText: 'Features (comma-separated)',
                  labelStyle: ETextStyles.inputLabel,
                  hintText: 'Unlimited classes, Priority booking',
                )),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: EColors.primary),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) return;
                final priceCents = ((double.tryParse(priceCtrl.text.trim()) ?? 0) * 100).round();
                final features = featuresCtrl.text.trim().isEmpty
                    ? <String>[]
                    : featuresCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                await _db.from('subscription_plans').insert({
                  'name':                nameCtrl.text.trim(),
                  'description':         descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  'price_cents':         priceCents,
                  'interval_type':       interval,
                  'stripe_price_id':     stripeCtrl.text.trim().isEmpty ? null : stripeCtrl.text.trim(),
                  'booking_discount_pct': int.tryParse(discountCtrl.text.trim()) ?? 0,
                  'features':            features,
                  'is_active':           true,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: Text('ADD', style: ETextStyles.button.copyWith(color: EColors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminSubscriptionPlans,
      isMaster: true,
      child: Scaffold(
        backgroundColor: EColors.surface,
        appBar: AppBar(
          backgroundColor: EColors.surface,
          title: Text('Subscription Plans', style: ETextStyles.h3),
          elevation: 0,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddDialog,
          backgroundColor: EColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _plans.isEmpty
                ? Center(child: Text('No plans yet. Tap + to add one.', style: ETextStyles.bodyMuted))
                : ListView.separated(
                    padding: const EdgeInsets.all(ESpacing.lg),
                    itemCount: _plans.length,
                    separatorBuilder: (_, _) => Divider(color: EColors.divider, height: 1),
                    itemBuilder: (_, i) {
                      final p = _plans[i];
                      final hasPriceId = (p['stripe_price_id'] as String?)?.isNotEmpty ?? false;
                      final isActive = p['is_active'] as bool? ?? true;
                      final priceCents = (p['price_cents'] as num?)?.toInt() ?? 0;
                      final dollars = priceCents ~/ 100;
                      final cents = priceCents % 100;
                      final price = cents == 0 ? '\$$dollars' : '\$$dollars.${cents.toString().padLeft(2, '0')}';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: ESpacing.md, vertical: ESpacing.xs),
                        title: Text(p['name'] as String? ?? '', style: ETextStyles.label),
                        subtitle: Text(
                          '$price / ${p['interval_type'] ?? 'monthly'}  •  ${p['booking_discount_pct'] ?? 0}% off',
                          style: ETextStyles.bodySmMuted,
                        ),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                            hasPriceId ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                            color: hasPriceId ? EColors.primary : EColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: ESpacing.xs),
                          Switch(
                            value: isActive,
                            onChanged: (_) => _toggleActive(p),
                            activeTrackColor: EColors.primary,
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: EColors.error),
                            onPressed: () => _delete(p['id'] as String),
                          ),
                        ]),
                      );
                    },
                  ),
      ),
    );
  }
}
