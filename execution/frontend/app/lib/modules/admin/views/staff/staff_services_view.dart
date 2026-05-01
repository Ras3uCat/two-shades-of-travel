import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../admin_shell.dart';

class StaffServicesView extends StatefulWidget {
  const StaffServicesView({super.key});

  @override
  State<StaffServicesView> createState() => _StaffServicesViewState();
}

class _StaffServicesViewState extends State<StaffServicesView> {
  final _db = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _services = [];
  Set<String> _myServiceIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return;

      final results = await Future.wait([
        _db.from('services').select().eq('is_active', true).order('category').order('name'),
        _db.from('artist_services').select('service_id').eq('artist_id', uid),
      ]);

      final services = List<Map<String, dynamic>>.from(results[0] as List);
      final myRows   = List<Map<String, dynamic>>.from(results[1] as List);
      final myIds    = myRows.map((r) => r['service_id'] as String).toSet();

      if (mounted) {
        setState(() {
          _services = services;
          _myServiceIds = myIds;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String serviceId, bool enabled) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;

    setState(() {
      if (enabled) {
        _myServiceIds.add(serviceId);
      } else {
        _myServiceIds.remove(serviceId);
      }
    });

    try {
      if (enabled) {
        await _db.from('artist_services').insert({'artist_id': uid, 'service_id': serviceId});
      } else {
        await _db.from('artist_services').delete().eq('artist_id', uid).eq('service_id', serviceId);
      }
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() {
          if (enabled) {
            _myServiceIds.remove(serviceId);
          } else {
            _myServiceIds.add(serviceId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update service.', style: ETextStyles.bodySm),
            backgroundColor: EColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.staffServices,
      isMaster: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(ESpacing.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: EColors.divider, width: 0.5)),
            ),
            child: Text('My Services', style: ETextStyles.h2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ESpacing.lg, vertical: ESpacing.sm),
            child: Text(
              'Toggle the services you offer. Clients can only book you for enabled services.',
              style: ETextStyles.bodySmMuted,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _services.isEmpty
                    ? Center(child: Text('No services found.', style: ETextStyles.bodyMuted))
                    : ListView.separated(
                        padding: const EdgeInsets.all(ESpacing.lg),
                        itemCount: _services.length,
                        separatorBuilder: (_, _) => const SizedBox(height: ESpacing.xs),
                        itemBuilder: (_, i) {
                          final svc      = _services[i];
                          final id       = svc['id'] as String;
                          final name     = svc['name'] as String? ?? '';
                          final category = svc['category'] as String? ?? '';
                          final price    = (svc['price'] as num?)?.toDouble() ?? 0.0;
                          final enabled  = _myServiceIds.contains(id);

                          return Container(
                            decoration: BoxDecoration(
                              color: EColors.surfaceVariant,
                              border: Border.all(color: EColors.divider, width: 0.5),
                            ),
                            child: SwitchListTile(
                              value: enabled,
                              activeTrackColor: EColors.primary,
                              onChanged: (v) => _toggle(id, v),
                              title: Text(name, style: ETextStyles.h4),
                              subtitle: Text(
                                '$category · \$${price.toStringAsFixed(0)}',
                                style: ETextStyles.bodySmMuted,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
