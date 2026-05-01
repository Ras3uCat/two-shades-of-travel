import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/events_admin_controller.dart';
import '../../models/event_model.dart';

class AdminEventsListView extends GetView<EventsAdminController> {
  const AdminEventsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        title: Text('Events', style: ETextStyles.h3),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _showEventDialog(context, null),
            icon: Icon(Icons.add, color: EColors.primary),
            label: Text('New Event', style: ETextStyles.label.copyWith(color: EColors.primary)),
          ),
          const SizedBox(width: ESpacing.sm),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: EColors.primary));
        }
        if (controller.events.isEmpty) {
          return Center(child: Text('No events yet.', style: ETextStyles.bodyMuted));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(ESpacing.md),
          itemCount: controller.events.length,
          separatorBuilder: (_, _) => const SizedBox(height: ESpacing.sm),
          itemBuilder: (_, i) => _EventRow(
            event: controller.events[i],
            onEdit: () => _showEventDialog(context, controller.events[i]),
            onAttendees: () => Get.toNamed(
              ERoutes.adminEventsAttendees.replaceFirst(':id', controller.events[i].id),
            ),
          ),
        );
      }),
    );
  }

  void _showEventDialog(BuildContext context, EventModel? existing) {
    showDialog<void>(
      context: context,
      builder: (_) => _EventDialog(existing: existing, controller: controller),
    );
  }
}

// ── Row ───────────────────────────────────────────────────────────────────────

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.onEdit,
    required this.onAttendees,
  });
  final EventModel   event;
  final VoidCallback onEdit;
  final VoidCallback onAttendees;

  Color get _statusColor {
    if (event.isPublished)  return EColors.primary;
    if (event.isCancelled) return EColors.error;
    return EColors.onSurfaceMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:  EColors.surfaceVariant,
        border: Border.all(color: EColors.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: ESpacing.md, vertical: ESpacing.xs),
        title: Text(event.title, style: ETextStyles.h4),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.formattedDateShort, style: ETextStyles.caption),
            if (event.venue != null)
              Text(event.venue!, style: ETextStyles.caption),
            const SizedBox(height: ESpacing.xxs),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: ESpacing.xs, vertical: 2),
              color: _statusColor.withValues(alpha: 0.12),
              child: Text(
                event.status.toUpperCase(),
                style: ETextStyles.labelSm.copyWith(color: _statusColor),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Attendees',
              onPressed: onAttendees,
              icon: Icon(Icons.people_outline, color: EColors.primary),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: EColors.onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class _EventDialog extends StatefulWidget {
  const _EventDialog({required this.existing, required this.controller});
  final EventModel?           existing;
  final EventsAdminController controller;

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  late final TextEditingController _title;
  late final TextEditingController _slug;
  late final TextEditingController _description;
  late final TextEditingController _venue;
  late final TextEditingController _imageUrl;
  late final TextEditingController _capacity;

  String   _status   = 'draft';
  DateTime _date      = DateTime.now().add(const Duration(days: 7));
  bool     _slugEdited = false;
  bool     _saving    = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title       = TextEditingController(text: e?.title ?? '');
    _slug        = TextEditingController(text: e?.slug ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _venue       = TextEditingController(text: e?.venue ?? '');
    _imageUrl    = TextEditingController(text: e?.heroImageUrl ?? '');
    _capacity    = TextEditingController(text: e != null ? '${e.capacity}' : '');
    _status      = e?.status ?? 'draft';
    _date        = e?.eventDate ?? DateTime.now().add(const Duration(days: 7));

    _title.addListener(_autoSlug);
    if (e != null) _slugEdited = true;
  }

  @override
  void dispose() {
    _title.removeListener(_autoSlug);
    for (final c in [_title, _slug, _description, _venue, _imageUrl, _capacity]) {
      c.dispose();
    }
    super.dispose();
  }

  void _autoSlug() {
    if (_slugEdited) return;
    final raw = _title.text.toLowerCase().trim();
    final buf = StringBuffer();
    bool lastDash = false;
    for (final ch in raw.runes) {
      final c = ch;
      if ((c >= 97 && c <= 122) || (c >= 48 && c <= 57)) {
        buf.writeCharCode(c);
        lastDash = false;
      } else if (!lastDash && buf.isNotEmpty) {
        buf.write('-');
        lastDash = true;
      }
    }
    var slug = buf.toString();
    if (slug.endsWith('-')) slug = slug.substring(0, slug.length - 1);
    _slug.text = slug;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (!mounted || picked == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted || time == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final cap = int.tryParse(_capacity.text);
    if (_title.text.trim().isEmpty || _slug.text.trim().isEmpty || cap == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'title':         _title.text.trim(),
        'slug':          _slug.text.trim(),
        'description':   _description.text.trim().isEmpty ? null : _description.text.trim(),
        'event_date':    _date.toUtc().toIso8601String(),
        'venue':         _venue.text.trim().isEmpty ? null : _venue.text.trim(),
        'hero_image_url': _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
        'capacity':      cap,
        'status':        _status,
      };
      if (widget.existing == null) {
        await widget.controller.createEvent(data);
      } else {
        await widget.controller.updateEvent(widget.existing!.id, data);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed. Check for duplicate slug.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Dialog(
      backgroundColor: EColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(ESpacing.lg, ESpacing.lg, ESpacing.md, 0),
              child: Row(children: [
                Expanded(child: Text(isNew ? 'New Event' : 'Edit Event', style: ETextStyles.h3)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller:  _title,
                      decoration:  InputDecoration(labelText: 'Title *', labelStyle: ETextStyles.inputLabel),
                      style:       ETextStyles.inputText,
                    ),
                    const SizedBox(height: ESpacing.md),
                    TextField(
                      controller:   _slug,
                      decoration:   InputDecoration(labelText: 'Slug *', labelStyle: ETextStyles.inputLabel),
                      style:        ETextStyles.inputText,
                      onChanged:    (_) => _slugEdited = true,
                    ),
                    const SizedBox(height: ESpacing.md),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date & time *',
                          labelStyle: ETextStyles.inputLabel,
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          '${_date.toLocal()}'.substring(0, 16),
                          style: ETextStyles.inputText,
                        ),
                      ),
                    ),
                    const SizedBox(height: ESpacing.md),
                    TextField(
                      controller:  _capacity,
                      decoration:  InputDecoration(labelText: 'Capacity *', labelStyle: ETextStyles.inputLabel),
                      style:       ETextStyles.inputText,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: ESpacing.md),
                    TextField(
                      controller:  _venue,
                      decoration:  InputDecoration(labelText: 'Venue', labelStyle: ETextStyles.inputLabel),
                      style:       ETextStyles.inputText,
                    ),
                    const SizedBox(height: ESpacing.md),
                    TextField(
                      controller:  _description,
                      decoration:  InputDecoration(labelText: 'Description', labelStyle: ETextStyles.inputLabel),
                      style:       ETextStyles.inputText,
                      maxLines:    3,
                    ),
                    const SizedBox(height: ESpacing.md),
                    TextField(
                      controller:  _imageUrl,
                      decoration:  InputDecoration(labelText: 'Hero image URL', labelStyle: ETextStyles.inputLabel),
                      style:       ETextStyles.inputText,
                    ),
                    const SizedBox(height: ESpacing.md),
                    StatefulBuilder(
                      builder: (_, setS) => InputDecorator(
                        decoration: InputDecoration(
                          labelText:  'Status',
                          labelStyle: ETextStyles.inputLabel,
                        ),
                        child: DropdownButton<String>(
                          value:           _status,
                          isExpanded:      true,
                          underline:       const SizedBox.shrink(),
                          dropdownColor:   EColors.surfaceVariant,
                          style:           ETextStyles.inputText,
                          onChanged:       (v) { if (v != null) setS(() => _status = v); },
                          items: const [
                            DropdownMenuItem(value: 'draft',     child: Text('Draft')),
                            DropdownMenuItem(value: 'published', child: Text('Published')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
