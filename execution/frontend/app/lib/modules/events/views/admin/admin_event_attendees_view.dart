import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/events_admin_controller.dart';
import '../../models/event_ticket_model.dart';
import 'admin_event_ticket_types_section.dart';

class AdminEventAttendeesView extends GetView<EventsAdminController> {
  const AdminEventAttendeesView({super.key});

  @override
  Widget build(BuildContext context) {
    final eventId = Get.parameters['id'] ?? '';
    if (eventId.isNotEmpty && controller.selectedEventId.value != eventId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadAttendees(eventId);
      });
    }

    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        title: Obx(() {
          final event = controller.events.firstWhereOrNull((e) => e.id == eventId);
          return Text(event?.title ?? 'Attendees', style: ETextStyles.h3);
        }),
        elevation: 0,
        actions: [
          Obx(() {
            final event = controller.events.firstWhereOrNull((e) => e.id == eventId);
            if (event == null || event.isCancelled) return const SizedBox.shrink();
            return TextButton(
              onPressed: controller.isCancelling.value
                  ? null
                  : () => _confirmCancel(context, eventId),
              child: Text(
                'Cancel Event',
                style: ETextStyles.label.copyWith(color: EColors.error),
              ),
            );
          }),
          const SizedBox(width: ESpacing.sm),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: EColors.primary));
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(ESpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatsBar(controller: controller),
                    const SizedBox(height: ESpacing.xl),
                    AdminEventTicketTypesSection(
                      eventId:    eventId,
                      controller: controller,
                    ),
                    const SizedBox(height: ESpacing.xl),
                    Row(children: [
                      Text('Attendees', style: ETextStyles.h3),
                      const SizedBox(width: ESpacing.sm),
                      Obx(() => Text(
                        '(${controller.attendees.length})',
                        style: ETextStyles.bodyMuted,
                      )),
                    ]),
                    const SizedBox(height: ESpacing.sm),
                  ],
                ),
              ),
            ),
            Obx(() {
              if (controller.attendees.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: ESpacing.lg),
                    child: Text('No attendees yet.', style: ETextStyles.bodyMuted),
                  ),
                );
              }
              return SliverList.separated(
                itemCount: controller.attendees.length,
                separatorBuilder: (_, _) => const SizedBox(height: ESpacing.xs),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ESpacing.lg),
                  child: _AttendeeRow(
                    ticket:    controller.attendees[i],
                    onCheckIn: () => controller.checkInTicket(controller.attendees[i].id),
                  ),
                ),
              );
            }),
            const SliverToBoxAdapter(child: SizedBox(height: ESpacing.xxl)),
          ],
        );
      }),
    );
  }

  void _confirmCancel(BuildContext context, String eventId) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: EColors.surface,
        title: Text('Cancel this event?', style: ETextStyles.h3),
        content: Text(
          'All confirmed tickets will be refunded via Stripe. This cannot be undone.',
          style: ETextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Keep event', style: ETextStyles.label),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.cancelEvent(eventId);
            },
            child: Text(
              'Yes, cancel & refund',
              style: ETextStyles.label.copyWith(color: EColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats bar ─────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.controller});
  final EventsAdminController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(children: [
      _Stat(label: 'Sold',       value: '${controller.totalSold}'),
      const SizedBox(width: ESpacing.md),
      _Stat(label: 'Confirmed',  value: '${controller.totalConfirmed}'),
      const SizedBox(width: ESpacing.md),
      _Stat(label: 'Checked In', value: '${controller.totalCheckedIn}'),
      const SizedBox(width: ESpacing.md),
      _Stat(
        label: 'Revenue',
        value: '\$${controller.totalRevenue.toStringAsFixed(2)}',
        accent: true,
      ),
    ]));
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.accent = false});
  final String label;
  final String value;
  final bool   accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(ESpacing.md),
        decoration: BoxDecoration(
          color:  accent
              ? EColors.primary.withValues(alpha: 0.08)
              : EColors.surfaceVariant,
          border: Border.all(color: EColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: ETextStyles.h3.copyWith(
                    color: accent ? EColors.primary : EColors.onSurface)),
            Text(label, style: ETextStyles.caption),
          ],
        ),
      ),
    );
  }
}

// ── Attendee row ──────────────────────────────────────────────────────────────

class _AttendeeRow extends StatelessWidget {
  const _AttendeeRow({required this.ticket, required this.onCheckIn});
  final EventTicketModel ticket;
  final VoidCallback     onCheckIn;

  Color get _statusColor {
    if (ticket.isCheckedIn) return EColors.primary;
    if (ticket.isConfirmed) return EColors.onSurface;
    return EColors.onSurfaceMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Text(ticket.buyerName, style: ETextStyles.label),
              Text(ticket.buyerEmail, style: ETextStyles.caption),
              const SizedBox(height: ESpacing.xxs),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ESpacing.xs, vertical: 2),
                  color: _statusColor.withValues(alpha: 0.12),
                  child: Text(
                    ticket.status.toUpperCase().replaceAll('_', ' '),
                    style: ETextStyles.labelSm.copyWith(color: _statusColor),
                  ),
                ),
                const SizedBox(width: ESpacing.sm),
                Text(
                  'x${ticket.quantity}  ·  ${ticket.formattedTotal}',
                  style: ETextStyles.caption,
                ),
              ]),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              ticket.codeDisplay,
              style: ETextStyles.label.copyWith(
                  letterSpacing: 2, color: EColors.primary),
            ),
            const SizedBox(height: ESpacing.xs),
            if (!ticket.isCheckedIn && ticket.isConfirmed)
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColors.primary,
                    foregroundColor: EColors.secondary,
                    padding: const EdgeInsets.symmetric(horizontal: ESpacing.md),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text('Check in', style: ETextStyles.labelSm),
                ),
              )
            else if (ticket.isCheckedIn)
              Text(
                'Checked in',
                style: ETextStyles.labelSm.copyWith(color: EColors.primary),
              ),
          ],
        ),
      ]),
    );
  }
}
