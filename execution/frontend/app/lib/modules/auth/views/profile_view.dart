import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_env.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../booking/models/booking_model.dart';
import '../../booking/repositories/booking_repository.dart';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: EColors.surface,
      body: Column(
        children: [
          _ProfileHeader(auth: auth),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.bookings.isEmpty && !AppEnv.loyaltyEnabled) {
                return Center(
                  child: Text('No bookings yet.', style: ETextStyles.bodyMuted),
                );
              }
              return ListView(
                padding: const EdgeInsets.all(ESpacing.lg),
                children: [
                  if (controller.bookings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: ESpacing.lg),
                      child: Center(
                        child: Text('No bookings yet.',
                            style: ETextStyles.bodyMuted),
                      ),
                    )
                  else
                    ...List.generate(controller.bookings.length, (i) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: ESpacing.sm),
                        child: _BookingCard(booking: controller.bookings[i]),
                      ),
                    ),
                  if (AppEnv.loyaltyEnabled)
                    _LoyaltySection(controller: controller),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.auth});
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          ESpacing.lg, ESpacing.xl, ESpacing.lg, ESpacing.lg),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border(bottom: BorderSide(color: EColors.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: EColors.primary, size: 28),
          const SizedBox(width: ESpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Bookings', style: ETextStyles.h2),
                Text(
                  auth.user?.email ?? '',
                  style: ETextStyles.bodySm
                      .copyWith(color: EColors.onSurfaceMuted),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              auth.signOut();
              Get.offAllNamed(ERoutes.home);
            },
            icon: Icon(Icons.logout, size: 16, color: EColors.onSurfaceMuted),
            label: Text('Sign out',
                style: ETextStyles.bodySm
                    .copyWith(color: EColors.onSurfaceMuted)),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends GetView<ProfileController> {
  const _BookingCard({required this.booking});
  final BookingModel booking;

  static const _statusColors = {
    'pending':   Color(0xFFF59E0B),
    'confirmed': Color(0xFF10B981),
    'cancelled': Color(0xFFEF4444),
    'completed': Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColors[booking.status] ?? EColors.onSurfaceMuted;

    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + status row
          Row(
            children: [
              Text(booking.formattedDate, style: ETextStyles.label),
              const SizedBox(width: ESpacing.sm),
              Text('·', style: ETextStyles.bodyMuted),
              const SizedBox(width: ESpacing.sm),
              Text(
                '${booking.formattedTime} → ${booking.formattedEndTime}',
                style: ETextStyles.bodySm,
              ),
              const Spacer(),
              if (AppEnv.recurringEnabled &&
                  booking.recurringSeriesId != null) ...[
                Icon(Icons.repeat, size: 14, color: EColors.onSurfaceMuted),
                const SizedBox(width: 4),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: ESpacing.sm, vertical: 3),
                color: statusColor.withValues(alpha: 0.15),
                child: Text(
                  booking.status.toUpperCase(),
                  style: ETextStyles.labelSm
                      .copyWith(color: statusColor, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: ESpacing.xs),
          Text(booking.artistName, style: ETextStyles.h4),
          Text(
            booking.serviceNames.join(', '),
            style: ETextStyles.bodySmMuted,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: ESpacing.xs),
          Text(
            '${booking.formattedDuration} · ${booking.formattedPrice}',
            style: ETextStyles.bodySm,
          ),
          // Action row
          const SizedBox(height: ESpacing.sm),
          Row(
            children: [
              TextButton(
                onPressed: () => _showReceipt(context, booking),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text('VIEW RECEIPT',
                    style: ETextStyles.labelSm
                        .copyWith(color: EColors.primary)),
              ),
              if (booking.status == 'completed') ...[
                const SizedBox(width: ESpacing.md),
                TextButton(
                  onPressed: () => Get.offAllNamed(
                    ERoutes.booking,
                    arguments: {
                      'artistId':   booking.artistId,
                      'serviceIds': booking.serviceIds,
                    },
                  ),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text('BOOK AGAIN',
                      style: ETextStyles.labelSm
                          .copyWith(color: EColors.primary)),
                ),
              ],
              if (AppEnv.recurringEnabled &&
                  booking.recurringSeriesId != null &&
                  booking.status == 'confirmed' &&
                  booking.startTime.isAfter(DateTime.now())) ...[
                const SizedBox(width: ESpacing.md),
                TextButton(
                  onPressed: () => _confirmCancelSeries(context, booking),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text('CANCEL SERIES',
                      style: ETextStyles.labelSm
                          .copyWith(color: EColors.error)),
                ),
              ],
              const Spacer(),
              Obx(() {
                final cancelling =
                    controller.isCancelling.value == booking.id;
                if (controller.canResumePayment(booking)) {
                  return TextButton(
                    onPressed: cancelling
                        ? null
                        : () => controller.resumePayment(booking.id),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text('COMPLETE PAYMENT',
                        style: ETextStyles.labelSm
                            .copyWith(color: const Color(0xFFF59E0B))),
                  );
                }
                if (controller.canCancel(booking)) {
                  return cancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          onPressed: () =>
                              _confirmCancel(context, booking),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero),
                          child: Text('CANCEL',
                              style: ETextStyles.labelSm
                                  .copyWith(color: EColors.error)),
                        );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmCancelSeries(BuildContext context, BookingModel booking) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: EColors.surface,
        title: Text('Cancel recurring series?', style: ETextStyles.h4),
        content: Text(
          'All future confirmed bookings in this series will be cancelled.',
          style: ETextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Keep series', style: ETextStyles.button),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              try {
                await Get.find<BookingRepository>()
                    .cancelRecurringSeries(booking.recurringSeriesId!);
                controller.loadBookings();
              } catch (_) {
                // ignore: use_build_context_synchronously
              }
            },
            child: Text('Yes, cancel all',
                style: ETextStyles.button.copyWith(color: EColors.error)),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, BookingModel booking) {
    final ctrl         = controller;
    final withinWindow = ctrl.isWithinCancellationWindow(booking);
    final refundPct    = ctrl.cancellationRefundPct;
    final hours        = ctrl.cancellationHours;

    final String policyText;
    if (hours == 0) {
      policyText = refundPct == 100
          ? 'Cancellations are accepted at any time with a full refund.'
          : 'Cancellations are accepted at any time. A $refundPct% refund applies.';
    } else if (withinWindow) {
      policyText = refundPct == 0
          ? 'This booking is within $hours hours of the appointment. '
              'Cancellations at this stage are non-refundable.'
          : 'This booking is within $hours hours of the appointment. '
              'Only a $refundPct% refund applies at this stage.';
    } else {
      policyText = refundPct == 100
          ? 'Cancellations made more than $hours hours before the appointment '
              'qualify for a full refund.'
          : 'Cancellations made more than $hours hours before the appointment '
              'qualify for a $refundPct% refund.';
    }

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: EColors.surface,
        title: Text('Cancel this booking?', style: ETextStyles.h4),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking summary
            Container(
              padding: const EdgeInsets.all(ESpacing.md),
              color: EColors.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.formattedDate, style: ETextStyles.label),
                  const SizedBox(height: ESpacing.xs),
                  Text(
                    '${booking.formattedTime} with ${booking.artistName}',
                    style: ETextStyles.body,
                  ),
                  Text(
                    booking.serviceNames.join(', '),
                    style: ETextStyles.bodySmMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: ESpacing.md),
            // Cancellation policy
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  withinWindow
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
                  size: 16,
                  color: withinWindow
                      ? const Color(0xFFF59E0B)
                      : EColors.onSurfaceMuted,
                ),
                const SizedBox(width: ESpacing.xs),
                Expanded(
                  child: Text(
                    policyText,
                    style: ETextStyles.bodySm.copyWith(
                      color: withinWindow
                          ? const Color(0xFFF59E0B)
                          : EColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Keep booking', style: ETextStyles.button),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              ctrl.cancelBooking(booking.id);
            },
            child: Text(
              'Yes, cancel',
              style: ETextStyles.button.copyWith(color: EColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showReceipt(BuildContext context, BookingModel b) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: EColors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ESpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Receipt', style: ETextStyles.h2),
                    const Spacer(),
                    IconButton(
                      onPressed: Get.back,
                      icon: Icon(Icons.close, color: EColors.onSurfaceMuted),
                    ),
                  ],
                ),
                const SizedBox(height: ESpacing.lg),
                _ReceiptRow('Booking ID', b.id.substring(0, 8).toUpperCase()),
                _ReceiptRow('Date', b.formattedDate),
                _ReceiptRow('Time',
                    '${b.formattedTime} → ${b.formattedEndTime}'),
                _ReceiptRow('Artist', b.artistName),
                _ReceiptRow('Services', b.serviceNames.join(', ')),
                _ReceiptRow('Duration', b.formattedDuration),
                const Divider(height: ESpacing.xl),
                _ReceiptRow('Total', b.formattedPrice,
                    valueStyle: ETextStyles.h4),
                _ReceiptRow('Status', b.status.toUpperCase()),
                if (b.paymentIntentId != null)
                  _ReceiptRow('Payment ref',
                      b.paymentIntentId!.substring(0, 16)),
                const SizedBox(height: ESpacing.lg),
                Text(
                  'Booked on ${DateFormat('MMM d, yyyy').format(b.createdAt)}',
                  style: ETextStyles.bodySmMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoyaltySection extends GetView<ProfileController> {
  const _LoyaltySection({required this.controller});

  @override
  // ignore: overridden_fields
  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pts   = controller.loyaltyBalance.value;
      final worth = (pts / 100.0); // 100 points = £1 (or $ — matches business logic)
      return Container(
        margin: const EdgeInsets.only(top: ESpacing.md),
        padding: const EdgeInsets.all(ESpacing.md),
        decoration: BoxDecoration(
          color: EColors.primary.withValues(alpha: 0.08),
          border: Border.all(color: EColors.primary.withValues(alpha: 0.3),
              width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.star_outline, color: EColors.primary, size: 24),
            const SizedBox(width: ESpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loyalty Balance', style: ETextStyles.label),
                Text(
                  '$pts points (worth \$${worth.toStringAsFixed(2)})',
                  style: ETextStyles.body,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow(this.label, this.value, {this.valueStyle});
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: ETextStyles.label
                  .copyWith(color: EColors.onSurfaceMuted)),
          Flexible(
            child: Text(value,
                style: valueStyle ?? ETextStyles.body,
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
