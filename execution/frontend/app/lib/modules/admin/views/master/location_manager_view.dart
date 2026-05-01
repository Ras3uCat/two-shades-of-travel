import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../../modules/location/location_controller.dart';
import '../../../../modules/location/location_model.dart';
import '../admin_shell.dart';

class LocationManagerView extends StatelessWidget {
  const LocationManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<LocationController>();
    return AdminShell(
      currentRoute: '/admin/locations',
      isMaster: true,
      child: Scaffold(
        backgroundColor: EColors.surface,
        body: Obx(() {
          if (ctrl.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(ESpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Locations', style: ETextStyles.h2),
                    FilledButton.icon(
                      onPressed: () => _showDialog(context, ctrl),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Location'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ctrl.locations.isEmpty
                    ? Center(
                        child: Text(
                          'No locations yet. Add your first location.',
                          style: ETextStyles.bodyMd
                              .copyWith(color: EColors.onSurfaceMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(ESpacing.lg),
                        itemCount: ctrl.locations.length,
                        separatorBuilder: (_, i) =>
                            const SizedBox(height: ESpacing.sm),
                        itemBuilder: (_, i) => _LocationTile(
                          location: ctrl.locations[i],
                          onEdit: () =>
                              _showDialog(context, ctrl, existing: ctrl.locations[i]),
                          onDelete: () =>
                              _confirmDelete(context, ctrl, ctrl.locations[i]),
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showDialog(
    BuildContext context,
    LocationController ctrl, {
    LocationModel? existing,
  }) {
    showDialog(
      context: context,
      builder: (_) => _LocationDialog(ctrl: ctrl, existing: existing),
    );
  }

  void _confirmDelete(
    BuildContext ctx,
    LocationController ctrl,
    LocationModel loc,
  ) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Location?'),
        content: Text(
          'Deleting "${loc.name}" will unlink all associated staff and bookings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ctrl.deleteLocation(loc.id);
            },
            child:
                Text('DELETE', style: TextStyle(color: EColors.error)),
          ),
        ],
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.location,
    required this.onEdit,
    required this.onDelete,
  });

  final LocationModel location;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.location_on_outlined,
          color: location.isActive ? EColors.primary : EColors.onSurfaceMuted,
        ),
        title: Text(location.name, style: ETextStyles.h4),
        subtitle: Text(
          [
            if (location.displayAddress.isNotEmpty) location.displayAddress,
            if (!location.isActive) 'Inactive',
          ].join(' · '),
          style: ETextStyles.bodyMd.copyWith(color: EColors.onSurfaceMuted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: EColors.error),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationDialog extends StatefulWidget {
  const _LocationDialog({required this.ctrl, this.existing});
  final LocationController ctrl;
  final LocationModel? existing;

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _timezone;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name     = TextEditingController(text: e?.name ?? '');
    _address  = TextEditingController(text: e?.address ?? '');
    _city     = TextEditingController(text: e?.city ?? '');
    _phone    = TextEditingController(text: e?.phone ?? '');
    _timezone = TextEditingController(text: e?.timezone ?? 'UTC');
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    _timezone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final ctrl = widget.ctrl;
    final id   = widget.existing?.id;
    if (id == null) {
      await ctrl.createLocation(
        name:      _name.text.trim(),
        address:   _address.text.trim(),
        city:      _city.text.trim(),
        phone:     _phone.text.trim(),
        timezone:  _timezone.text.trim().isEmpty ? 'UTC' : _timezone.text.trim(),
      );
    } else {
      await ctrl.updateLocation(id, {
        'name':      _name.text.trim(),
        'address':   _address.text.trim(),
        'city':      _city.text.trim(),
        'phone':     _phone.text.trim(),
        'timezone':  _timezone.text.trim().isEmpty ? 'UTC' : _timezone.text.trim(),
        'is_active': _isActive,
      });
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Location' : 'Add Location'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Location Name *'),
              ),
              const SizedBox(height: ESpacing.md),
              TextField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Street Address'),
              ),
              const SizedBox(height: ESpacing.md),
              TextField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: ESpacing.md),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: ESpacing.md),
              TextField(
                controller: _timezone,
                decoration: const InputDecoration(
                  labelText: 'Timezone',
                  hintText: 'America/New_York',
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: ESpacing.sm),
                StatefulBuilder(
                  builder: (_, setState) => SwitchListTile(
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeTrackColor: EColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEdit ? 'SAVE' : 'ADD'),
        ),
      ],
    );
  }
}
