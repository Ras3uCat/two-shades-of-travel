import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_env.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../models/subscription_plan_model.dart';

class SubscriptionsView extends StatefulWidget {
  const SubscriptionsView({super.key});

  @override
  State<SubscriptionsView> createState() => _SubscriptionsViewState();
}

class _SubscriptionsViewState extends State<SubscriptionsView> {
  List<SubscriptionPlanModel> _plans = [];
  bool _loading = true;
  String? _error;
  bool _showSuccessBanner = false;

  @override
  void initState() {
    super.initState();
    final params = Get.parameters;
    if (params['subscribed'] == '1') _showSuccessBanner = true;
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final rows = await Supabase.instance.client
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('display_order');
      if (mounted) {
        setState(() {
          _plans = (rows as List)
              .map((r) => SubscriptionPlanModel.fromMap(r as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load plans.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        title: Text('Memberships', style: ETextStyles.h3),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: ETextStyles.body))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final width = MediaQuery.sizeOf(context).width;
    final crossCount = width >= ESpacing.tabletBreak ? 3 : (width >= ESpacing.mobileBreak ? 2 : 1);
    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: ESpacing.pagePaddingH, vertical: ESpacing.lg),
      children: [
        if (_showSuccessBanner)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: ESpacing.lg),
            padding: const EdgeInsets.all(ESpacing.md),
            color: EColors.primary.withValues(alpha: 0.1),
            child: Row(children: [
              Icon(Icons.check_circle_outline, color: EColors.primary),
              const SizedBox(width: ESpacing.sm),
              Expanded(
                child: Text(
                  "You're subscribed! Welcome aboard.",
                  style: ETextStyles.body.copyWith(color: EColors.primary),
                ),
              ),
            ]),
          ),
        if (_plans.isEmpty)
          Center(child: Text('No plans available yet.', style: ETextStyles.bodyMuted))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: ESpacing.md,
              mainAxisSpacing: ESpacing.md,
              childAspectRatio: 0.75,
            ),
            itemCount: _plans.length,
            itemBuilder: (_, i) => _PlanCard(plan: _plans[i]),
          ),
      ],
    );
  }
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({required this.plan});
  final SubscriptionPlanModel plan;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _subscribing = false;

  Future<void> _subscribe() async {
    final plan = widget.plan;
    final stripeOff = AppEnv.stripeMode == 'none' || AppEnv.stripePk.isEmpty;
    if (stripeOff || plan.stripePriceId == null || plan.stripePriceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact us to subscribe to this plan.')),
      );
      return;
    }
    setState(() => _subscribing = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-subscription-checkout',
        body: {
          'price_id':   plan.stripePriceId,
          'plan_id':    plan.id,
          'success_url': '${AppEnv.siteUrl}/subscriptions?subscribed=1',
          'cancel_url':  '${AppEnv.siteUrl}/subscriptions',
        },
      );
      final url = response.data['url'] as String;
      await launchUrl(Uri.parse(url));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start checkout. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Container(
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider),
      ),
      padding: const EdgeInsets.all(ESpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan.name, style: ETextStyles.h4),
          if (plan.description != null) ...[
            const SizedBox(height: ESpacing.xs),
            Text(plan.description!, style: ETextStyles.bodySmMuted),
          ],
          const SizedBox(height: ESpacing.md),
          Text(plan.formattedPrice, style: ETextStyles.price),
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: ESpacing.md),
            ...plan.features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: ESpacing.xxs),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check, size: 14, color: EColors.primary),
                const SizedBox(width: ESpacing.xs),
                Expanded(child: Text(f, style: ETextStyles.bodySm)),
              ]),
            )),
          ],
          const Spacer(),
          const SizedBox(height: ESpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _subscribing ? null : _subscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: EColors.primary,
                foregroundColor: EColors.white,
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(vertical: ESpacing.md),
              ),
              child: _subscribing
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('SUBSCRIBE', style: ETextStyles.button.copyWith(color: EColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
