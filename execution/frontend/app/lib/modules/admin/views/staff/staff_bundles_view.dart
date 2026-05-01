import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../admin_shell.dart';

class StaffBundlesView extends StatefulWidget {
  const StaffBundlesView({super.key});

  @override
  State<StaffBundlesView> createState() => _StaffBundlesViewState();
}

class _StaffBundlesViewState extends State<StaffBundlesView> {
  final _db = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _bundles  = [];
  List<Map<String, dynamic>> _myServices = [];

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
        _db.from('packages').select().eq('artist_id', uid).order('name'),
        _db
            .from('artist_services')
            .select('service_id, services(id, name)')
            .eq('artist_id', uid),
      ]);

      if (mounted) {
        setState(() {
          _bundles    = List<Map<String, dynamic>>.from(results[0] as List);
          _myServices = List<Map<String, dynamic>>.from(results[1] as List);
          _loading    = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id) async {
    try {
      await _db.from('packages').delete().eq('id', id);
      if (mounted) setState(() => _bundles.removeWhere((b) => b['id'] == id));
    } catch (_) {
      if (mounted) {
        Get.snackbar('Error', 'Failed to delete bundle.',
            backgroundColor: EColors.error, colorText: EColors.white);
      }
    }
  }

  Future<void> _toggleActive(String id, bool value) async {
    try {
      await _db.from('packages').update({'is_active': value}).eq('id', id);
      if (mounted) {
        setState(() {
          final idx = _bundles.indexWhere((b) => b['id'] == id);
          if (idx != -1) _bundles[idx] = {..._bundles[idx], 'is_active': value};
        });
      }
    } catch (_) {}
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final discCtrl = TextEditingController(text: '0');
    final descCtrl = TextEditingController();
    final selected = <String>{};

    Get.dialog(StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: EColors.surface,
        title: Text('New Bundle', style: ETextStyles.h3),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: ETextStyles.inputText,
                  decoration: InputDecoration(
                    labelText: 'Bundle Name',
                    labelStyle: ETextStyles.inputLabel,
                  ),
                ),
                const SizedBox(height: ESpacing.md),
                TextField(
                  controller: discCtrl,
                  keyboardType: TextInputType.number,
                  style: ETextStyles.inputText,
                  decoration: InputDecoration(
                    labelText: 'Discount %',
                    labelStyle: ETextStyles.inputLabel,
                  ),
                ),
                const SizedBox(height: ESpacing.md),
                TextField(
                  controller: descCtrl,
                  style: ETextStyles.inputText,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: ETextStyles.inputLabel,
                  ),
                ),
                const SizedBox(height: ESpacing.md),
                Text('Include Services', style: ETextStyles.label),
                const SizedBox(height: ESpacing.sm),
                ..._myServices.map((row) {
                  final svc  = row['services'] as Map<String, dynamic>?;
                  final sid  = svc?['id'] as String? ?? '';
                  final name = svc?['name'] as String? ?? sid;
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: selected.contains(sid),
                    activeColor: EColors.primary,
                    title: Text(name, style: ETextStyles.bodySm),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          selected.add(sid);
                        } else {
                          selected.remove(sid);
                        }
                      });
                    },
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('CANCEL',
                style: ETextStyles.button.copyWith(color: EColors.onSurfaceMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Get.back();
              await _createBundle(
                name:        nameCtrl.text.trim(),
                discountPct: double.tryParse(discCtrl.text) ?? 0,
                description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                serviceIds:  selected.toList(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.white,
              shape: const RoundedRectangleBorder(),
            ),
            child: Text('CREATE', style: ETextStyles.button),
          ),
        ],
      ),
    ));
  }

  Future<void> _createBundle({
    required String name,
    required double discountPct,
    String? description,
    required List<String> serviceIds,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _db.from('packages').insert({
        'artist_id':    uid,
        'name':         name,
        'discount_pct': discountPct,
        'description':  description,
        'service_ids':  serviceIds,
        'is_active':    true,
      });
      await _load();
    } catch (_) {
      if (mounted) {
        Get.snackbar('Error', 'Failed to create bundle.',
            backgroundColor: EColors.error, colorText: EColors.white);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.staffBundles,
      isMaster: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(ESpacing.lg),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: EColors.divider, width: 0.5)),
            ),
            child: Row(children: [
              Text('My Bundles', style: ETextStyles.h2),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: Text('NEW BUNDLE', style: ETextStyles.button),
                onPressed: _showAddDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EColors.primary,
                  foregroundColor: EColors.white,
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _bundles.isEmpty
                    ? Center(child: Text('No bundles yet.', style: ETextStyles.bodyMuted))
                    : ListView.separated(
                        padding: const EdgeInsets.all(ESpacing.lg),
                        itemCount: _bundles.length,
                        separatorBuilder: (_, _) => const SizedBox(height: ESpacing.sm),
                        itemBuilder: (_, i) {
                          final b         = _bundles[i];
                          final id        = b['id'] as String;
                          final name      = b['name'] as String? ?? '';
                          final disc      = (b['discount_pct'] as num?)?.toDouble() ?? 0.0;
                          final isActive  = b['is_active'] as bool? ?? true;
                          final svcIds    = (b['service_ids'] as List?)?.length ?? 0;

                          return Dismissible(
                            key: ValueKey(id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              color: EColors.error,
                              padding: const EdgeInsets.only(right: ESpacing.lg),
                              child: Icon(Icons.delete_outline, color: EColors.white),
                            ),
                            onDismissed: (_) => _delete(id),
                            child: Container(
                              padding: const EdgeInsets.all(ESpacing.md),
                              decoration: BoxDecoration(
                                color: EColors.surfaceVariant,
                                border: Border.all(color: EColors.divider, width: 0.5),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: ETextStyles.h4),
                                      Text(
                                        '$svcIds service${svcIds == 1 ? '' : 's'} · ${disc.toStringAsFixed(0)}% off',
                                        style: ETextStyles.bodySmMuted,
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  activeTrackColor: EColors.primary,
                                  onChanged: (v) => _toggleActive(id, v),
                                ),
                              ]),
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
