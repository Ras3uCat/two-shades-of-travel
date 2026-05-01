import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../admin_shell.dart';

class GiftVouchersView extends StatefulWidget {
  const GiftVouchersView({super.key});

  @override
  State<GiftVouchersView> createState() => _GiftVouchersViewState();
}

class _GiftVouchersViewState extends State<GiftVouchersView> {
  List<Map<String, dynamic>> _vouchers = [];
  bool _loading = true;
  String? _error;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _db
          .from('gift_vouchers')
          .select()
          .order('created_at', ascending: false);
      setState(() => _vouchers = List<Map<String, dynamic>>.from(rows as List));
    } catch (e) {
      setState(() => _error = 'Failed to load vouchers.');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _status(Map<String, dynamic> v) {
    if (v['redeemed_at'] != null) return 'Redeemed';
    final exp = v['expires_at'] as String?;
    if (exp != null && DateTime.tryParse(exp)?.isBefore(DateTime.now()) == true) {
      return 'Expired';
    }
    return 'Active';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Redeemed': return const Color(0xFF6B7280);
      case 'Expired':  return EColors.error;
      default:         return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminGiftVouchers,
      isMaster: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(onRefresh: _load),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, style: ETextStyles.bodyMuted));
    }
    if (_vouchers.isEmpty) {
      return Center(
          child: Text('No gift vouchers yet.', style: ETextStyles.bodyMuted));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(ESpacing.lg),
      itemCount: _vouchers.length,
      separatorBuilder: (_, _) => const SizedBox(height: ESpacing.sm),
      itemBuilder: (_, i) {
        final v      = _vouchers[i];
        final status = _status(v);
        final amount = ((v['amount_cents'] as num?)?.toInt() ?? 0) / 100;
        final date   = v['created_at'] as String?;
        final fmt    = date != null
            ? DateFormat('MMM d, yyyy').format(DateTime.parse(date).toLocal())
            : '—';

        return Container(
          padding: const EdgeInsets.all(ESpacing.md),
          decoration: BoxDecoration(
            color: EColors.surfaceVariant,
            border: Border.all(color: EColors.divider, width: 0.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v['code'] as String? ?? '—',
                        style: ETextStyles.h4),
                    Text(
                      '${v['purchased_by_email'] ?? '—'} → ${v['recipient_email'] ?? '—'}',
                      style: ETextStyles.bodySm
                          .copyWith(color: EColors.onSurfaceMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ESpacing.md),
              Text('£${amount.toStringAsFixed(0)}',
                  style: ETextStyles.h4),
              const SizedBox(width: ESpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: ESpacing.sm, vertical: 3),
                    color: _statusColor(status).withValues(alpha: 0.15),
                    child: Text(
                      status.toUpperCase(),
                      style: ETextStyles.labelSm.copyWith(
                          color: _statusColor(status), fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(fmt,
                      style: ETextStyles.labelSm
                          .copyWith(color: EColors.onSurfaceMuted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESpacing.lg),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: EColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Text('Gift Vouchers', style: ETextStyles.h2),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: EColors.onSurfaceMuted),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
