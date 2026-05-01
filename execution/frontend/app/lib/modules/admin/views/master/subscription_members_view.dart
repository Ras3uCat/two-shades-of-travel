import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../views/admin_shell.dart';

class SubscriptionMembersView extends StatefulWidget {
  const SubscriptionMembersView({super.key});

  @override
  State<SubscriptionMembersView> createState() => _SubscriptionMembersViewState();
}

class _SubscriptionMembersViewState extends State<SubscriptionMembersView> {
  SupabaseClient get _db => Supabase.instance.client;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  bool _activeOnly = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    var q = _db
        .from('subscriptions')
        .select('id, client_email, client_name, status, current_period_end, plan_id, subscription_plans(name)');
    if (_activeOnly) q = q.inFilter('status', ['active', 'trialing']);
    final rows = await q.order('created_at', ascending: false);
    if (mounted) {
      setState(() {
        _rows = (rows as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    }
  }

  Future<void> _cancel(String id) async {
    await _db.from('subscriptions').update({'status': 'cancelled'}).eq('id', id);
    _load();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':    return Colors.green;
      case 'trialing':  return Colors.blue;
      case 'past_due':  return Colors.orange;
      default:          return EColors.onSurfaceMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminSubscriptionMembers,
      isMaster: true,
      child: Scaffold(
        backgroundColor: EColors.surface,
        appBar: AppBar(
          backgroundColor: EColors.surface,
          title: Text('Subscribers', style: ETextStyles.h3),
          elevation: 0,
          actions: [
            Row(children: [
              Text('Active only', style: ETextStyles.bodySm),
              Switch(
                value: _activeOnly,
                onChanged: (v) { setState(() => _activeOnly = v); _load(); },
                activeTrackColor: EColors.primary,
              ),
              const SizedBox(width: ESpacing.sm),
            ]),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _rows.isEmpty
                ? Center(child: Text('No subscribers found.', style: ETextStyles.bodyMuted))
                : ListView.separated(
                    padding: const EdgeInsets.all(ESpacing.lg),
                    itemCount: _rows.length,
                    separatorBuilder: (_, _) => Divider(color: EColors.divider, height: 1),
                    itemBuilder: (_, i) {
                      final r = _rows[i];
                      final status = r['status'] as String? ?? 'active';
                      final planName = (r['subscription_plans'] as Map?)?['name'] as String? ?? '—';
                      final periodEnd = r['current_period_end'] != null
                          ? DateFormat('MMM d, yyyy').format(
                              DateTime.parse(r['current_period_end'] as String).toLocal())
                          : '—';
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: ESpacing.md, vertical: ESpacing.xs),
                        title: Text(r['client_name'] as String? ?? '', style: ETextStyles.label),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['client_email'] as String? ?? '', style: ETextStyles.bodySmMuted),
                            Text('$planName  •  renews $periodEnd', style: ETextStyles.bodySmMuted),
                          ],
                        ),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: ESpacing.xs, vertical: ESpacing.xxs),
                            color: _statusColor(status).withValues(alpha: 0.12),
                            child: Text(
                              status.toUpperCase(),
                              style: ETextStyles.labelSm.copyWith(color: _statusColor(status)),
                            ),
                          ),
                          if (status != 'cancelled') ...[
                            const SizedBox(width: ESpacing.xs),
                            IconButton(
                              icon: Icon(Icons.cancel_outlined, color: EColors.error),
                              tooltip: 'Cancel subscription',
                              onPressed: () => _cancel(r['id'] as String),
                            ),
                          ],
                        ]),
                      );
                    },
                  ),
      ),
    );
  }
}
