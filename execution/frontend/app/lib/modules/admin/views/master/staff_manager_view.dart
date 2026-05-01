import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/master_controller.dart';
import '../admin_shell.dart';
import 'staff_calendar_dialog.dart';

class StaffManagerView extends GetView<MasterController> {
  const StaffManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminStaff,
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
              Text('Team Profiles', style: ETextStyles.h2),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.refresh, color: EColors.onSurfaceMuted),
                onPressed: controller.loadAll,
              ),
            ]),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.staffProfiles.isEmpty) {
                return Center(
                    child: Text('No staff profiles found.',
                        style: ETextStyles.bodyMuted));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(ESpacing.lg),
                itemCount: controller.staffProfiles.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: ESpacing.sm),
                itemBuilder: (_, i) => _StaffTile(
                  profile: controller.staffProfiles[i],
                  onEdit: () => _showEditForm(
                      context, controller.staffProfiles[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showEditForm(
      BuildContext context, Map<String, dynamic> profile) {
    final nameCtrl  = TextEditingController(
        text: profile['display_name'] as String? ?? '');
    final bioCtrl   = TextEditingController(
        text: profile['bio'] as String? ?? '');
    final photoCtrl = TextEditingController(
        text: profile['photo_url'] as String? ?? '');
    final specCtrl  = TextEditingController(
        text: ((profile['specialties'] as List?)
                ?.cast<String>()
                .join(', ') ??
            ''));

    Get.dialog(AlertDialog(
      backgroundColor: EColors.surface,
      title: Text('Edit Profile', style: ETextStyles.h3),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Field(controller: nameCtrl,  label: 'Display name'),
              const SizedBox(height: ESpacing.md),
              _Field(controller: bioCtrl,   label: 'Bio',
                  maxLines: 3),
              const SizedBox(height: ESpacing.md),
              _Field(controller: photoCtrl, label: 'Photo URL'),
              const SizedBox(height: ESpacing.md),
              _Field(controller: specCtrl,
                  label: 'Specialties (comma-separated)'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text('CANCEL',
              style: ETextStyles.button
                  .copyWith(color: EColors.onSurfaceMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: EColors.primary,
            foregroundColor: EColors.secondary,
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: () async {
            final specs = specCtrl.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            final photo = photoCtrl.text.trim();
            Get.back();
            await controller.updateStaffProfile(
              profile['id'] as String,
              {
                'display_name': nameCtrl.text.trim(),
                'bio':          bioCtrl.text.trim(),
                'photo_url':    photo.isEmpty ? null : photo,
                'specialties':  specs,
              },
            );
          },
          child: Text('SAVE', style: ETextStyles.button),
        ),
      ],
    ));
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.profile, required this.onEdit});
  final Map<String, dynamic> profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name      = profile['display_name'] as String? ?? '—';
    final bio       = profile['bio']       as String? ?? '';
    final photoUrl  = profile['photo_url'] as String?;
    final role      = profile['role']      as String? ?? '';
    final specs     = (profile['specialties'] as List?)
            ?.cast<String>()
            .where((s) => s.isNotEmpty)
            .join(', ') ??
        '';

    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider, width: 0.5),
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: EColors.primaryLight,
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: photoUrl != null
              ? Image.network(photoUrl, fit: BoxFit.cover)
              : Icon(Icons.person_outline,
                  color: EColors.primary, size: 28),
        ),
        const SizedBox(width: ESpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(name, style: ETextStyles.h4),
                const SizedBox(width: ESpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  color: EColors.primaryLight,
                  child: Text(role.toUpperCase(),
                      style: ETextStyles.labelSm
                          .copyWith(color: EColors.primary, fontSize: 9)),
                ),
              ]),
              if (specs.isNotEmpty)
                Text(specs, style: ETextStyles.bodySmMuted),
              if (bio.isNotEmpty)
                Text(bio,
                    style: ETextStyles.bodySmMuted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Calendar feed',
          icon: Icon(Icons.calendar_today_outlined,
              color: EColors.onSurfaceMuted, size: 18),
          onPressed: () => Get.dialog(StaffCalendarDialog(
            staffId:   profile['id']           as String,
            staffName: (profile['display_name'] as String?) ?? '—',
          )),
        ),
        IconButton(
          icon: Icon(Icons.edit_outlined,
              color: EColors.onSurfaceMuted, size: 18),
          onPressed: onEdit,
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.controller, required this.label, this.maxLines = 1});
  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: ETextStyles.inputText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: ETextStyles.inputLabel,
      ),
    );
  }
}
