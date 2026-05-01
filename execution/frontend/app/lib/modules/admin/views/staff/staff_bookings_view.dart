import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../booking/models/booking_model.dart';
import '../../controllers/staff_controller.dart';
import '../admin_shell.dart';
import '../../../../shared/widgets/calendar_sync_widget.dart';

class StaffBookingsView extends GetView<StaffController> {
  const StaffBookingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.staff,
      isMaster: false,
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(ESpacing.lg),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: EColors.divider, width: 0.5)),
                ),
                child: Text('My Bookings', style: ETextStyles.h2),
              ),
              const CalendarSyncWidget(),
              TabBar(
                tabs: const [Tab(text: 'UPCOMING'), Tab(text: 'PAST')],
                labelStyle: ETextStyles.label,
                labelColor: EColors.primary,
                unselectedLabelColor: EColors.onSurfaceMuted,
                indicatorColor: EColors.primary,
                indicatorWeight: 1.5,
                dividerColor: EColors.divider,
              ),
              Expanded(
                child: TabBarView(children: [
                  _BookingList(bookings: controller.upcomingBookings),
                  _BookingList(bookings: controller.pastBookings),
                ]),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.bookings});
  final List<BookingModel> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
          child: Text('No bookings.', style: ETextStyles.bodyMuted));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(ESpacing.lg),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: ESpacing.sm),
      itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final BookingModel booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surfaceVariant,
        border: Border.all(color: EColors.divider, width: 0.5),
      ),
      child: Row(children: [
        // Date block
        Container(
          width: 48,
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
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(booking.clientName, style: ETextStyles.h4),
            Text(booking.clientEmail,
                style: ETextStyles.bodySm.copyWith(
                    color: EColors.onSurfaceMuted)),
            const SizedBox(height: ESpacing.xs),
            Text(
              '${booking.formattedTime} · ${booking.formattedDuration}',
              style: ETextStyles.bodySm.copyWith(color: EColors.primary),
            ),
            Text(booking.serviceNames.join(', '),
                style: ETextStyles.bodySmMuted,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        Text(booking.formattedPrice,
            style: ETextStyles.price.copyWith(fontSize: 16)),
      ]),
    );
  }
}
