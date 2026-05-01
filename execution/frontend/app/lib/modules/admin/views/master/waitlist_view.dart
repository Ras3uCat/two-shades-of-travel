import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../admin_shell.dart';

class WaitlistView extends StatefulWidget {
  const WaitlistView({super.key});

  @override
  State<WaitlistView> createState() => _WaitlistViewState();
}

class _WaitlistViewState extends State<WaitlistView> {
  List<Map<String, dynamic>> _entries = [];
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
          .from('waitlist')
          .select('*, profiles!artist_id(display_name)')
          .order('created_at', ascending: false)
          .limit(200);
      setState(() =>
          _entries = List<Map<String, dynamic>>.from(rows as List));
    } catch (_) {
      setState(() => _error = 'Failed to load waitlist.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _remove(String id) async {
    try {
      await _db.from('waitlist').delete().eq('id', id);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminWaitlist,
      isMaster: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(ESpacing.lg),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: EColors.divider, width: 0.5)),
            ),
            child: Row(children: [
              Text('Waitlist', style: ETextStyles.h2),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, color: EColors.onSurfaceMuted),
                onPressed: _load,
              ),
            ]),
          ),
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
    if (_entries.isEmpty) {
      return Center(
          child: Text('No one on the waitlist.', style: ETextStyles.bodyMuted));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(ESpacing.lg),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: ESpacing.sm),
      itemBuilder: (_, i) {
        final e          = _entries[i];
        final id         = e['id'] as String;
        final name       = e['client_name'] as String? ?? '—';
        final email      = e['client_email'] as String? ?? '—';
        final artistName = (e['profiles'] as Map?)?['display_name'] as String? ?? '—';
        final prefDate   = e['preferred_date'] as String?;
        final notified   = e['notified_at'] != null;
        final created    = e['created_at'] as String?;
        final createdFmt = created != null
            ? DateFormat('MMM d, yyyy').format(DateTime.parse(created).toLocal())
            : '—';

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: ESpacing.lg),
            color: EColors.error.withValues(alpha: 0.15),
            child: Icon(Icons.delete_outline, color: EColors.error),
          ),
          confirmDismiss: (_) async {
            await _remove(id);
            return false;
          },
          child: Container(
            padding: const EdgeInsets.all(ESpacing.md),
            decoration: BoxDecoration(
              color: EColors.surfaceVariant,
              border: Border.all(color: EColors.divider, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: ETextStyles.h4),
                      Text(email,
                          style: ETextStyles.bodySm
                              .copyWith(color: EColors.onSurfaceMuted)),
                      const SizedBox(height: ESpacing.xs),
                      Text('Artist: $artistName',
                          style: ETextStyles.bodySmMuted),
                      if (prefDate != null)
                        Text('Preferred: $prefDate',
                            style: ETextStyles.bodySmMuted),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: ESpacing.sm, vertical: 3),
                      color: notified
                          ? EColors.onSurfaceMuted.withValues(alpha: 0.15)
                          : EColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        notified ? 'NOTIFIED' : 'WAITING',
                        style: ETextStyles.labelSm.copyWith(
                          color: notified
                              ? EColors.onSurfaceMuted
                              : EColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: ESpacing.xs),
                    Text(createdFmt,
                        style: ETextStyles.labelSm
                            .copyWith(color: EColors.onSurfaceMuted)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
