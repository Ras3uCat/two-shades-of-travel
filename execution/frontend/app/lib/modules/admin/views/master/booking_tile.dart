import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../booking/models/booking_model.dart';
import '../../controllers/master_controller.dart';

class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking});
  final BookingModel booking;

  static const _statusColors = {
    'pending':   Color(0xFFF59E0B),
    'confirmed': Color(0xFF10B981),
    'cancelled': Color(0xFFEF4444),
    'completed': Color(0xFF6B7280),
  };

  @override
  Widget build(BuildContext context) {
    final ctrl        = Get.find<MasterController>();
    final statusColor = _statusColors[booking.status] ?? EColors.onSurfaceMuted;

    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider, width: 0.5),
      ),
      child: Row(
        children: [
          // Date block
          Container(
            width: 52,
            alignment: Alignment.center,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                DateFormat('MMM').format(booking.startTime).toUpperCase(),
                style: ETextStyles.labelSm.copyWith(color: EColors.primary),
              ),
              Text('${booking.startTime.day}', style: ETextStyles.h2),
            ]),
          ),
          const SizedBox(width: ESpacing.md),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.clientName, style: ETextStyles.h4),
                Text(booking.clientEmail,
                    style: ETextStyles.bodySm
                        .copyWith(color: EColors.onSurfaceMuted)),
                const SizedBox(height: ESpacing.xs),
                Text(
                  '${booking.formattedTime} · ${booking.artistName} · ${booking.formattedPrice}',
                  style: ETextStyles.bodySm,
                ),
                Text(
                  booking.serviceNames.join(', '),
                  style: ETextStyles.bodySmMuted,
                  overflow: TextOverflow.ellipsis,
                ),
                if (booking.clientNotes != null &&
                    booking.clientNotes!.isNotEmpty)
                  Text(
                    'Note: ${booking.clientNotes}',
                    style: ETextStyles.bodySm.copyWith(
                        color: EColors.onSurfaceMuted,
                        fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: ESpacing.md),
          // Status + actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
              const SizedBox(height: ESpacing.xs),
              if (booking.status == 'pending')
                TextButton(
                  onPressed: () =>
                      ctrl.updateBookingStatus(booking.id, 'confirmed'),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text('CONFIRM',
                      style: ETextStyles.labelSm
                          .copyWith(color: EColors.primary)),
                ),
              if (booking.status != 'cancelled' &&
                  booking.status != 'completed')
                TextButton(
                  onPressed: () =>
                      ctrl.updateBookingStatus(booking.id, 'cancelled'),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text('CANCEL',
                      style:
                          ETextStyles.labelSm.copyWith(color: EColors.error)),
                ),
              if (AppEnv.stripeInvoicingEnabled &&
                  booking.status == 'confirmed')
                TextButton(
                  onPressed: () => ctrl.sendStripeInvoice(booking.id),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text(
                    booking.stripeInvoiceId != null
                        ? 'RESEND INVOICE'
                        : 'SEND INVOICE',
                    style: ETextStyles.labelSm
                        .copyWith(color: EColors.onSurfaceMuted),
                  ),
                ),
              if (AppEnv.invoicesEnabled && booking.status == 'confirmed')
                TextButton(
                  onPressed: () => ctrl.sendInvoice(booking.id),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, minimumSize: Size.zero),
                  child: Text(
                    booking.invoiceNumber != null
                        ? 'RESEND PDF INVOICE'
                        : 'GENERATE PDF INVOICE',
                    style: ETextStyles.labelSm
                        .copyWith(color: EColors.onSurfaceMuted),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
