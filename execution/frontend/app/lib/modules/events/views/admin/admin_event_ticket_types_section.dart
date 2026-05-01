import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/events_admin_controller.dart';
import '../../models/event_ticket_type_model.dart';

/// Embedded widget for the attendees view — shows ticket type list + CRUD.
class AdminEventTicketTypesSection extends StatelessWidget {
  const AdminEventTicketTypesSection({
    super.key,
    required this.eventId,
    required this.controller,
  });
  final String                eventId;
  final EventsAdminController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text('Ticket Types', style: ETextStyles.h3)),
          TextButton.icon(
            onPressed: () => _showDialog(context, null),
            icon: Icon(Icons.add, size: 16, color: EColors.primary),
            label: Text('Add', style: ETextStyles.label.copyWith(color: EColors.primary)),
          ),
        ]),
        const SizedBox(height: ESpacing.sm),
        Obx(() {
          if (controller.ticketTypes.isEmpty) {
            return Text('No ticket types.', style: ETextStyles.bodyMuted);
          }
          return Column(
            children: controller.ticketTypes.map((t) => _TypeRow(
              type:     t,
              onEdit:   () => _showDialog(context, t),
              onDelete: () => _confirmDelete(context, t),
            )).toList(),
          );
        }),
      ],
    );
  }

  void _showDialog(BuildContext context, EventTicketTypeModel? existing) {
    showDialog<void>(
      context: context,
      builder: (_) => _TicketTypeDialog(
        existing:   existing,
        eventId:    eventId,
        controller: controller,
      ),
    );
  }

  void _confirmDelete(BuildContext context, EventTicketTypeModel type) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: EColors.surface,
        title: Text('Delete ticket type?', style: ETextStyles.h3),
        content: Text(
          'This cannot be undone. Ticket types with confirmed tickets cannot be deleted.',
          style: ETextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: ETextStyles.label),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteTicketType(type.id);
            },
            child: Text('Delete', style: ETextStyles.label.copyWith(color: EColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Row ───────────────────────────────────────────────────────────────────────

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.onEdit,
    required this.onDelete,
  });
  final EventTicketTypeModel type;
  final VoidCallback         onEdit;
  final VoidCallback         onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: ESpacing.xs),
      padding: const EdgeInsets.symmetric(
          horizontal: ESpacing.md, vertical: ESpacing.sm),
      decoration: BoxDecoration(
        color:  EColors.surfaceVariant,
        border: Border.all(color: EColors.divider),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type.name, style: ETextStyles.label),
              Text(
                '${type.formattedPrice}  ·  ${type.quantityTotal} capacity',
                style: ETextStyles.caption,
              ),
              if (type.description != null)
                Text(type.description!, style: ETextStyles.caption),
            ],
          ),
        ),
        IconButton(
          tooltip:  'Edit',
          onPressed: onEdit,
          icon: Icon(Icons.edit_outlined, size: 18, color: EColors.onSurfaceMuted),
        ),
        IconButton(
          tooltip:  'Delete',
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, size: 18, color: EColors.error),
        ),
      ]),
    );
  }
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class _TicketTypeDialog extends StatefulWidget {
  const _TicketTypeDialog({
    required this.existing,
    required this.eventId,
    required this.controller,
  });
  final EventTicketTypeModel? existing;
  final String                eventId;
  final EventsAdminController controller;

  @override
  State<_TicketTypeDialog> createState() => _TicketTypeDialogState();
}

class _TicketTypeDialogState extends State<_TicketTypeDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _quantity;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _name        = TextEditingController(text: t?.name ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _price       = TextEditingController(
        text: t != null ? t.price.toStringAsFixed(2) : '');
    _quantity    = TextEditingController(
        text: t != null ? '${t.quantityTotal}' : '');
  }

  @override
  void dispose() {
    for (final c in [_name, _description, _price, _quantity]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    final priceDouble = double.tryParse(_price.text);
    final qty         = int.tryParse(_quantity.text);
    if (_name.text.trim().isEmpty || priceDouble == null || qty == null || qty < 1) return;

    setState(() => _saving = true);
    try {
      final data = {
        'name':           _name.text.trim(),
        'description':    _description.text.trim().isEmpty ? null : _description.text.trim(),
        'price_cents':    (priceDouble * 100).round(),
        'quantity_total': qty,
      };
      if (widget.existing == null) {
        await widget.controller.createTicketType(widget.eventId, data);
      } else {
        await widget.controller.updateTicketType(widget.existing!.id, data);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save failed. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: EColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 480),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(ESpacing.lg, ESpacing.lg, ESpacing.md, 0),
              child: Row(children: [
                Expanded(
                  child: Text(
                    widget.existing == null ? 'New Ticket Type' : 'Edit Ticket Type',
                    style: ETextStyles.h3,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ]),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(ESpacing.lg),
                child: Column(children: [
                  TextField(
                    controller:  _name,
                    decoration:  InputDecoration(labelText: 'Name *', labelStyle: ETextStyles.inputLabel),
                    style:       ETextStyles.inputText,
                  ),
                  const SizedBox(height: ESpacing.md),
                  TextField(
                    controller:   _description,
                    decoration:   InputDecoration(labelText: 'Description', labelStyle: ETextStyles.inputLabel),
                    style:        ETextStyles.inputText,
                    maxLines:     2,
                  ),
                  const SizedBox(height: ESpacing.md),
                  TextField(
                    controller:   _price,
                    decoration:   InputDecoration(
                      labelText:  'Price (0 = free) *',
                      labelStyle: ETextStyles.inputLabel,
                      prefixText:  '\$',
                    ),
                    style:        ETextStyles.inputText,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: ESpacing.md),
                  TextField(
                    controller:   _quantity,
                    decoration:   InputDecoration(labelText: 'Quantity *', labelStyle: ETextStyles.inputLabel),
                    style:        ETextStyles.inputText,
                    keyboardType: TextInputType.number,
                  ),
                ]),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(ESpacing.md),
              child: Row(children: [
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: ETextStyles.label),
                ),
                const SizedBox(width: ESpacing.sm),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColors.primary,
                    foregroundColor: EColors.secondary,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: ESpacing.lg, vertical: ESpacing.md),
                  ),
                  child: _saving
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Save', style: ETextStyles.button),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
