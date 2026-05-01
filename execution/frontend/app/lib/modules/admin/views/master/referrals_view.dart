import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../views/admin_shell.dart';

class ReferralsView extends StatefulWidget {
  const ReferralsView({super.key});

  @override
  State<ReferralsView> createState() => _ReferralsViewState();
}

class _ReferralsViewState extends State<ReferralsView> {
  SupabaseClient get _db => Supabase.instance.client;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  bool _unrewardedOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    var q = _db.from('referrals').select();
    if (_unrewardedOnly) q = q.isFilter('rewarded_at', null);
    final rows = await q.order('created_at', ascending: false);
    if (mounted) {
      setState(() {
        _rows = (rows as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    }
  }

  Future<void> _markRewarded(String id) async {
    final referrerCtrl = TextEditingController();
    final referredCtrl  = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark as Rewarded', style: ETextStyles.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: referrerCtrl,
              decoration: const InputDecoration(labelText: 'Referrer promo code'),
            ),
            const SizedBox(height: ESpacing.sm),
            TextField(
              controller: referredCtrl,
              decoration: const InputDecoration(labelText: 'Referred promo code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db.from('referrals').update({
      'rewarded_at':         DateTime.now().toUtc().toIso8601String(),
      'referrer_promo_code': referrerCtrl.text.trim().isEmpty
          ? null
          : referrerCtrl.text.trim(),
      'referred_promo_code': referredCtrl.text.trim().isEmpty
          ? null
          : referredCtrl.text.trim(),
    }).eq('id', id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminReferrals,
      isMaster: true,
      child: Scaffold(
        backgroundColor: EColors.surface,
        appBar: AppBar(
          backgroundColor: EColors.surface,
          elevation: 0,
          title: Text('Referrals', style: ETextStyles.h3),
          actions: [
            Row(children: [
              Text('Unrewarded only', style: ETextStyles.bodySm),
              Switch(
                value: _unrewardedOnly,
                onChanged: (v) {
                  setState(() => _unrewardedOnly = v);
                  _load();
                },
                activeTrackColor: EColors.primary,
              ),
              const SizedBox(width: ESpacing.sm),
            ]),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _rows.isEmpty
                ? Center(
                    child: Text('No referrals found.',
                        style: ETextStyles.bodyMuted))
                : ListView.separated(
                    padding: const EdgeInsets.all(ESpacing.lg),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) =>
                        Divider(color: EColors.divider, height: 1),
                    itemBuilder: (_, i) => _buildRow(_rows[i]),
                  ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> r) {
    final rewarded   = r['rewarded_at'] != null;
    final refCode    = r['referral_code'] as String? ?? '—';
    final email      = r['referred_email'] as String? ?? '—';
    final created    = r['created_at'] != null
        ? DateFormat('MMM d, yyyy')
            .format(DateTime.parse(r['created_at'] as String).toLocal())
        : '—';
    final refPromo   = r['referrer_promo_code'] as String?;
    final redPromo   = r['referred_promo_code'] as String?;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: ESpacing.md, vertical: ESpacing.xs),
      title: Text(email, style: ETextStyles.label),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Code: $refCode  •  $created', style: ETextStyles.bodySmMuted),
          if (rewarded && (refPromo != null || redPromo != null))
            Text(
              'Codes: ${refPromo ?? '—'} / ${redPromo ?? '—'}',
              style: ETextStyles.bodySmMuted,
            ),
        ],
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: ESpacing.xs, vertical: 2),
          color: (rewarded ? Colors.green : EColors.onSurfaceMuted)
              .withValues(alpha: 0.12),
          child: Text(
            rewarded ? 'REWARDED' : 'PENDING',
            style: ETextStyles.labelSm.copyWith(
              color: rewarded ? Colors.green : EColors.onSurfaceMuted,
            ),
          ),
        ),
        if (!rewarded) ...[
          const SizedBox(width: ESpacing.xs),
          TextButton(
            onPressed: () => _markRewarded(r['id'] as String),
            child: const Text('Mark Rewarded'),
          ),
        ],
      ]),
    );
  }
}
