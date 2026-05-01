import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../admin_shell.dart';

class IntakeQuestionsView extends StatefulWidget {
  const IntakeQuestionsView({super.key});

  @override
  State<IntakeQuestionsView> createState() => _IntakeQuestionsViewState();
}

class _IntakeQuestionsViewState extends State<IntakeQuestionsView> {
  List<Map<String, dynamic>> _questions = [];
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
          .from('intake_questions')
          .select()
          .order('display_order');
      setState(() =>
          _questions = List<Map<String, dynamic>>.from(rows as List));
    } catch (_) {
      setState(() => _error = 'Failed to load questions.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(String id, bool current) async {
    try {
      await _db
          .from('intake_questions')
          .update({'is_active': !current})
          .eq('id', id);
      await _load();
    } catch (_) {}
  }

  Future<void> _deactivate(String id) async {
    try {
      await _db
          .from('intake_questions')
          .update({'is_active': false})
          .eq('id', id);
      await _load();
    } catch (_) {}
  }

  Future<void> _showAddDialog() async {
    final labelCtrl = TextEditingController();
    String fieldType   = 'text';
    bool   isRequired  = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: EColors.surface,
          title: Text('Add Question', style: ETextStyles.h4),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  style: ETextStyles.inputText,
                  decoration: InputDecoration(
                    labelText: 'Question label',
                    labelStyle: ETextStyles.inputLabel,
                  ),
                ),
                const SizedBox(height: ESpacing.md),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Field type',
                    labelStyle: ETextStyles.inputLabel,
                    isDense: true,
                    border: const UnderlineInputBorder(),
                  ),
                  child: DropdownButton<String>(
                    value: fieldType,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    style: ETextStyles.inputText,
                    items: const ['text', 'textarea', 'yesno', 'select']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => fieldType = v);
                    },
                  ),
                ),
                const SizedBox(height: ESpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Required', style: ETextStyles.body),
                  value: isRequired,
                  activeTrackColor: EColors.primary,
                  onChanged: (v) => setLocal(() => isRequired = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('Cancel', style: ETextStyles.button),
            ),
            ElevatedButton(
              onPressed: () async {
                final label = labelCtrl.text.trim();
                if (label.isEmpty) return;
                try {
                  await _db.from('intake_questions').insert({
                    'label':         label,
                    'field_type':    fieldType,
                    'is_required':   isRequired,
                    'is_active':     true,
                    'display_order': _questions.length,
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
    labelCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminIntake,
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
            child: Row(
              children: [
                Text('Intake Questions', style: ETextStyles.h2),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, color: EColors.onSurfaceMuted),
                  onPressed: _load,
                ),
              ],
            ),
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
    return Stack(
      children: [
        _questions.isEmpty
            ? Center(
                child: Text('No questions yet. Add one below.',
                    style: ETextStyles.bodyMuted))
            : ListView.separated(
                padding: const EdgeInsets.all(ESpacing.lg),
                itemCount: _questions.length,
                separatorBuilder: (_, _) => const SizedBox(height: ESpacing.sm),
                itemBuilder: (_, i) {
                  final q          = _questions[i];
                  final id         = q['id'] as String;
                  final label      = q['label'] as String? ?? '—';
                  final fieldType  = q['field_type'] as String? ?? 'text';
                  final isRequired = q['is_required'] as bool? ?? false;
                  final isActive   = q['is_active'] as bool? ?? true;

                  return Dismissible(
                    key: Key(id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding:
                          const EdgeInsets.symmetric(horizontal: ESpacing.lg),
                      color: EColors.error.withValues(alpha: 0.15),
                      child: Icon(Icons.visibility_off_outlined,
                          color: EColors.error),
                    ),
                    confirmDismiss: (_) async {
                      await _deactivate(id);
                      return false; // list reloads via _deactivate
                    },
                    child: Container(
                      padding: const EdgeInsets.all(ESpacing.md),
                      decoration: BoxDecoration(
                        color: isActive
                            ? EColors.surfaceVariant
                            : EColors.surfaceVariant
                                .withValues(alpha: 0.4),
                        border: Border.all(
                            color: EColors.divider, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(label,
                                        style: ETextStyles.h4.copyWith(
                                          color: isActive
                                              ? EColors.onSurface
                                              : EColors.onSurfaceMuted,
                                        )),
                                  ),
                                  if (isRequired)
                                    Text(' *',
                                        style: ETextStyles.labelSm
                                            .copyWith(color: EColors.error)),
                                ]),
                                const SizedBox(height: ESpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: ESpacing.sm, vertical: 2),
                                  color: EColors.primary
                                      .withValues(alpha: 0.12),
                                  child: Text(fieldType.toUpperCase(),
                                      style: ETextStyles.labelSm.copyWith(
                                          color: EColors.primary,
                                          fontSize: 10)),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeTrackColor: EColors.primary,
                            onChanged: (_) => _toggleActive(id, isActive),
                          ),
                        ],
                      ),
                    ),
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
      ],
    );
  }
}
