import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_env.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../../core/push/push_service.dart';
import '../../../shared/services/ics_service.dart';
import '../models/booking_model.dart';
import 'recurring_dialog.dart';

/// Shown after a successful booking.
/// Two entry points:
///  1. In-app (no Stripe): receives BookingModel via Get.arguments
///  2. Post-Stripe redirect: arrives via URL params ?booking_id=xxx&paid=1
class BookingConfirmationView extends StatelessWidget {
  const BookingConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    final booking   = Get.arguments as BookingModel?;
    final bookingId = Get.parameters['booking_id'];
    final fromStripe = bookingId != null && booking == null;
    final isMobile   = MediaQuery.sizeOf(context).width < ESpacing.mobileBreak;

    return Scaffold(
      backgroundColor: EColors.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? ESpacing.lg : ESpacing.xxl),
            child: booking != null
                ? _ConfirmationCard(booking: booking)
                : fromStripe
                    ? _PaymentConfirmedCard()
                    : _NoBooking(),
          ),
        ),
      ),
    );
  }
}

class _ConfirmationCard extends StatefulWidget {
  const _ConfirmationCard({required this.booking});
  final BookingModel booking;

  @override
  State<_ConfirmationCard> createState() => _ConfirmationCardState();
}

class _ConfirmationCardState extends State<_ConfirmationCard> {
  @override
  void initState() {
    super.initState();
    // Request push permission at highest-intent moment (post-booking).
    // Silent no-op if disabled, denied, or not web.
    if (AppEnv.pushEnabled) {
      requestAndSavePush(widget.booking.clientEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline,
            color: EColors.primary, size: 48),
        const SizedBox(height: ESpacing.lg),
        Text('You\'re booked.', style: ETextStyles.displayMd),
        const SizedBox(height: ESpacing.sm),
        Text(
          'A confirmation will be sent to ${booking.clientEmail}.',
          style: ETextStyles.bodyMuted,
        ),
        const SizedBox(height: ESpacing.xxl),
        _Row('Artist', booking.artistName),
        _Row('Date', booking.formattedDate),
        _Row('Time', '${booking.formattedTime} → ${booking.formattedEndTime}'),
        _Row('Services', booking.serviceNames.join(', ')),
        _Row('Duration', booking.formattedDuration),
        _Row('Total', booking.formattedPrice),
        const SizedBox(height: ESpacing.xxl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.offAllNamed(ERoutes.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.secondary,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: ESpacing.md),
            ),
            child: Text('BACK TO HOME', style: ETextStyles.button),
          ),
        ),
        const SizedBox(height: ESpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => IcsService.addToCalendar(booking),
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text('ADD TO CALENDAR', style: ETextStyles.button),
            style: OutlinedButton.styleFrom(
              foregroundColor: EColors.onSurface,
              side: BorderSide(color: EColors.divider),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: ESpacing.md),
            ),
          ),
        ),
        if (AppEnv.recurringEnabled) ...[
          const SizedBox(height: ESpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => RecurringDialog(booking: booking),
              ),
              icon: const Icon(Icons.repeat, size: 16),
              label: Text('SET UP RECURRING', style: ETextStyles.button),
              style: OutlinedButton.styleFrom(
                foregroundColor: EColors.primary,
                side: BorderSide(color: EColors.primary.withValues(alpha: 0.5)),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(vertical: ESpacing.md),
              ),
            ),
          ),
        ],
        const SizedBox(height: ESpacing.sm),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Get.offAllNamed(ERoutes.booking),
            child: Text('BOOK ANOTHER',
                style: ETextStyles.button.copyWith(
                    color: EColors.onSurfaceMuted)),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: ETextStyles.label.copyWith(color: EColors.onSurfaceMuted)),
          Flexible(
              child: Text(value,
                  style: ETextStyles.body,
                  textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _PaymentConfirmedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, color: EColors.primary, size: 48),
        const SizedBox(height: ESpacing.lg),
        Text('Payment confirmed.', style: ETextStyles.displayMd),
        const SizedBox(height: ESpacing.sm),
        Text(
          'Your booking is confirmed. Check your email for full details.',
          style: ETextStyles.bodyMuted,
        ),
        const SizedBox(height: ESpacing.xxl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.offAllNamed(ERoutes.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.secondary,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: ESpacing.md),
            ),
            child: Text('BACK TO HOME', style: ETextStyles.button),
          ),
        ),
        const SizedBox(height: ESpacing.md),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Get.offAllNamed(ERoutes.booking),
            child: Text('BOOK ANOTHER',
                style: ETextStyles.button.copyWith(
                    color: EColors.onSurfaceMuted)),
          ),
        ),
      ],
    );
  }
}

class _NoBooking extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: EColors.error, size: 48),
        const SizedBox(height: ESpacing.lg),
        Text('No booking found.', style: ETextStyles.h2),
        const SizedBox(height: ESpacing.xl),
        ElevatedButton(
          onPressed: () => Get.offAllNamed(ERoutes.home),
          style: ElevatedButton.styleFrom(
            backgroundColor: EColors.primary,
            foregroundColor: EColors.secondary,
            shape: const RoundedRectangleBorder(),
          ),
          child: Text('GO HOME', style: ETextStyles.button),
        ),
      ],
    );
  }
}
