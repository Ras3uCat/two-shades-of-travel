import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../admin_shell.dart';

class PackagesView extends StatefulWidget {
  const PackagesView({super.key});

  @override
  State<PackagesView> createState() => _PackagesViewState();
}

class _PackagesViewState extends State<PackagesView> {
  List<Map<String, dynamic>> _packages  = [];
  List<Map<String, dynamic>> _services  = [];
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
      final results = await Future.wait([
        _db.from('packages').select().order('display_order'),
        _db.from('services').select('id, name').eq('is_active', true).order('name'),
      ]);
      setState(() {
        _packages = List<Map<String, dynamic>>.from(results[0] as List);
        _services = List<Map<String, dynamic>>.from(results[1] as List);
      });
    } catch (_) {
      setState(() => _error = 'Failed to load packages.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(String id, bool current) async {
    try {
      await _db.from('packages').update({'is_active': !current}).eq('id', id);
      await _load();
    } catch (_) {}
  }

  Future<void> _delete(String id) async {
    try {
      await _db.from('packages').delete().eq('id', id);
      await _load();
    } catch (_) {}
  }

  Future<void> _showAddDialog() async {
    final nameCtrl  = TextEditingController();
    final descCtrl  = TextEditingController();
    final discCtrl  = TextEditingController(text: '0');
    final priceCtrl = TextEditingController();
    final selected  = <String>{};

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: EColors.surface,
          title: Text('Add Package', style: ETextStyles.h4),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: ETextStyles.inputText,
                    decoration: InputDecoration(
                      labelText: 'Package name *',
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
                  TextField(
                    controller: discCtrl,
                    style: ETextStyles.inputText,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Discount % (0–100)',
                      labelStyle: ETextStyles.inputLabel,
                    ),
                  ),
                  const SizedBox(height: ESpacing.md),
                  TextField(
                    controller: priceCtrl,
                    style: ETextStyles.inputText,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Price override (optional, e.g. 99.00)',
                      labelStyle: ETextStyles.inputLabel,
                    ),
                  ),
                  const SizedBox(height: ESpacing.md),
                  Text('Services *', style: ETextStyles.label),
                  const SizedBox(height: ESpacing.xs),
                  ..._services.map((svc) {
                    final id   = svc['id'] as String;
                    final name = svc['name'] as String? ?? id;
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(name, style: ETextStyles.body),
                      value: selected.contains(id),
                      activeColor: EColors.primary,
                      onChanged: (_) => setLocal(() {
                        if (selected.contains(id)) {
                          selected.remove(id);
                        } else {
                          selected.add(id);
                        }
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel', style: ETextStyles.button),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty || selected.isEmpty) return;
                final disc  = int.tryParse(discCtrl.text.trim()) ?? 0;
                final price = double.tryParse(priceCtrl.text.trim());
                try {
                  await _db.from('packages').insert({
                    'name':          name,
                    'description':   descCtrl.text.trim().isEmpty
                        ? null
                        : descCtrl.text.trim(),
                    'service_ids':   selected.toList(),
                    'discount_pct':   disc.clamp(0, 100),
                    'price_override': price,
                    'is_active':      true,
                    'display_order': _packages.length,
                  });
                  if (ctx.mounted) Get.back();
                  await _load();
                } catch (_) {}
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EColors.primary,
                foregroundColor: EColors.secondary,
                shape: const RoundedRectangleBorder(),
              ),
              child: Text('Add', style: ETextStyles.button),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    descCtrl.dispose();
    discCtrl.dispose();
    priceCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminPackages,
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
              Text('Packages', style: ETextStyles.h2),
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
    return Stack(children: [
      _packages.isEmpty
          ? Center(
              child: Text('No packages yet. Tap + to add one.',
                  style: ETextStyles.bodyMuted))
          : ListView.separated(
              padding: const EdgeInsets.all(ESpacing.lg),
              itemCount: _packages.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: ESpacing.sm),
              itemBuilder: (_, i) {
                final pkg      = _packages[i];
                final id       = pkg['id'] as String;
                final name     = pkg['name'] as String? ?? '—';
                final disc     = (pkg['discount_pct'] as num?)?.toInt() ?? 0;
                final price    = (pkg['price_override'] as num?)?.toDouble();
                final svcIds   = (pkg['service_ids'] as List?)?.length ?? 0;
                final isActive = pkg['is_active'] as bool? ?? true;

                return Container(
                  padding: const EdgeInsets.all(ESpacing.md),
                  decoration: BoxDecoration(
                    color: isActive
                        ? EColors.surfaceVariant
                        : EColors.surfaceVariant.withValues(alpha: 0.4),
                    border: Border.all(color: EColors.divider, width: 0.5),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: ETextStyles.h4.copyWith(
                                color: isActive
                                    ? EColors.onSurface
                                    : EColors.onSurfaceMuted,
                              )),
                          const SizedBox(height: ESpacing.xs),
                          Text(
                            '$svcIds service${svcIds == 1 ? '' : 's'}'
                            '${disc > 0 ? ' · $disc% off' : ''}'
                            '${price != null ? ' · \$${price.toStringAsFixed(2)}' : ''}',
                            style: ETextStyles.bodySmMuted,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      activeTrackColor: EColors.primary,
                      onChanged: (_) => _toggleActive(id, isActive),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: EColors.error, size: 20),
                      onPressed: () => _delete(id),
                    ),
                  ]),
                );
              },
            ),
      Positioned(
        bottom: ESpacing.lg,
        right: ESpacing.lg,
        child: FloatingActionButton(
          backgroundColor: EColors.primary,
          foregroundColor: EColors.secondary,
          onPressed: _showAddDialog,
          child: const Icon(Icons.add),
        ),
      ),
    ]);
  }
}
