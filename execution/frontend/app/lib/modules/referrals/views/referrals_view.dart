import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_env.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../../core/theme/e_spacing.dart';
import '../models/referral_model.dart';

class ReferralsView extends StatefulWidget {
  const ReferralsView({super.key});

  @override
  State<ReferralsView> createState() => _ReferralsViewState();
}

class _ReferralsViewState extends State<ReferralsView> {
  SupabaseClient get _db => Supabase.instance.client;

  String? _referralCode;
  Map<String, dynamic>? _stats;
  List<ReferralModel> _referrals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (_db.auth.currentUser != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = _db.auth.currentUser!.id;
      final profileRow = await _db
          .from('profiles')
          .select('referral_code')
          .eq('id', uid)
          .single();
      _referralCode = profileRow['referral_code'] as String?;

      final statsResult = await _db.rpc('get_referral_stats');
      _stats = statsResult as Map<String, dynamic>?;

      final rows = await _db
          .from('referrals')
          .select()
          .eq('referrer_id', uid)
          .order('created_at', ascending: false);
      _referrals = (rows as List)
          .map((r) => ReferralModel.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // ignore — show empty state
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyLink() async {
    final code = _referralCode;
    if (code == null) return;
    final link = '${AppEnv.siteUrl}/booking?ref=$code';
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _db.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: EColors.surface,
        elevation: 0,
        title: Text('Refer a Friend', style: ETextStyles.h3),
      ),
      backgroundColor: EColors.surface,
      body: user == null ? _buildUnauthenticated() : _buildContent(),
    );
  }

  Widget _buildUnauthenticated() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ESpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sign in to access your referral link',
                style: ETextStyles.body, textAlign: TextAlign.center),
            const SizedBox(height: ESpacing.lg),
            ElevatedButton(
              onPressed: () => Get.toNamed(ERoutes.login),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(ESpacing.lg),
      children: [
        _buildLinkSection(),
        const SizedBox(height: ESpacing.xl),
        _buildStatsRow(),
        const SizedBox(height: ESpacing.xl),
        Text('Your Referrals', style: ETextStyles.h4),
        const SizedBox(height: ESpacing.md),
        ..._buildReferralList(),
      ],
    );
  }

  Widget _buildLinkSection() {
    final code = _referralCode ?? '';
    final link = '${AppEnv.siteUrl}/booking?ref=$code';
    return Container(
      padding: const EdgeInsets.all(ESpacing.lg),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Referral Link', style: ETextStyles.label),
          const SizedBox(height: ESpacing.sm),
          Text(
            code.isEmpty ? 'No code assigned yet.' : link,
            style: ETextStyles.bodySm,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ESpacing.md),
          ElevatedButton.icon(
            onPressed: code.isEmpty ? null : _copyLink,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('COPY LINK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final total    = (_stats?['total']    as num?)?.toInt() ?? 0;
    final rewarded = (_stats?['rewarded'] as num?)?.toInt() ?? 0;
    final pending  = (_stats?['pending']  as num?)?.toInt() ?? 0;
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Total',    value: total)),
        const SizedBox(width: ESpacing.sm),
        Expanded(child: _StatCard(label: 'Rewarded', value: rewarded)),
        const SizedBox(width: ESpacing.sm),
        Expanded(child: _StatCard(label: 'Pending',  value: pending)),
      ],
    );
  }

  List<Widget> _buildReferralList() {
    if (_referrals.isEmpty) {
      return [
        Text(
          'No referrals yet. Share your link to get started.',
          style: ETextStyles.bodyMuted,
        ),
      ];
    }
    return _referrals
        .map((r) => Padding(
              padding: const EdgeInsets.only(bottom: ESpacing.sm),
              child: _ReferralRow(referral: r),
            ))
        .toList();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: ESpacing.md, horizontal: ESpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: EColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text('$value', style: ETextStyles.h3),
          const SizedBox(height: ESpacing.xxs),
          Text(label, style: ETextStyles.bodySmMuted),
        ],
      ),
    );
  }
}

class _ReferralRow extends StatelessWidget {
  const _ReferralRow({required this.referral});
  final ReferralModel referral;

  @override
  Widget build(BuildContext context) {
    final rewarded = referral.isRewarded;
    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: EColors.divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              referral.referredEmail,
              style: ETextStyles.bodySm,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: ESpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: ESpacing.xs, vertical: 2),
            decoration: BoxDecoration(
              color: (rewarded ? Colors.green : EColors.onSurfaceMuted)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              rewarded ? 'Rewarded' : 'Pending',
              style: ETextStyles.labelSm.copyWith(
                color: rewarded ? Colors.green : EColors.onSurfaceMuted,
              ),
            ),
          ),
          if (rewarded && referral.referrerPromoCode != null) ...[
            const SizedBox(width: ESpacing.sm),
            Text(referral.referrerPromoCode!,
                style: ETextStyles.labelSm
                    .copyWith(color: EColors.primary)),
          ],
        ],
      ),
    );
  }
}
