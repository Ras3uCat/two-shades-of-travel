import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_env.dart';
import '../../../core/router/app_router.dart';
import '../../booking/models/booking_model.dart';
import '../../booking/repositories/booking_repository.dart';

class ProfileController extends GetxController {
  final BookingRepository _repo = Get.find<BookingRepository>();

  final bookings        = <BookingModel>[].obs;
  final isLoading       = false.obs;
  final isCancelling    = ''.obs; // booking id currently being cancelled, '' = none
  final loyaltyBalance  = 0.obs;

  // Cancellation policy from business_config
  int cancellationHours     = 24;
  int cancellationRefundPct = 100;

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  Future<void> _loadAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        loadBookings(),
        _loadCancellationPolicy(),
        if (AppEnv.loyaltyEnabled) _loadLoyaltyBalance(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadBookings() async {
    try {
      bookings.value = await _repo.getUserBookings();
    } catch (_) {
      bookings.value = [];
    }
  }

  Future<void> _loadLoyaltyBalance() async {
    try {
      final email = Supabase.instance.client.auth.currentUser?.email;
      if (email == null) return;
      final rows = await Supabase.instance.client
          .from('loyalty_ledger')
          .select('points')
          .eq('client_email', email);
      final total = (rows as List).fold<int>(
          0, (sum, r) => sum + ((r['points'] as num?)?.toInt() ?? 0));
      loyaltyBalance.value = total;
    } catch (_) {
      // keep default 0
    }
  }

  Future<void> _loadCancellationPolicy() async {
    try {
      final row = await Supabase.instance.client
          .from('business_config')
          .select('cancellation_hours, cancellation_refund_pct')
          .limit(1)
          .single();
      cancellationHours     = (row['cancellation_hours']     as num).toInt();
      cancellationRefundPct = (row['cancellation_refund_pct'] as num).toInt();
    } catch (_) {
      // keep defaults
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    isCancelling.value = bookingId;
    try {
      // cancel-booking Edge Function handles Stripe refund + staff notification
      await _repo.cancelBooking(bookingId);
      await loadBookings();
    } catch (_) {
      // Edge Function rejects unauthorized attempts
    } finally {
      isCancelling.value = '';
    }
  }

  Future<void> resumePayment(String bookingId) async {
    try {
      final url = await _repo.createCheckoutSession(
        bookingId:  bookingId,
        successUrl: '${AppEnv.siteUrl}${ERoutes.confirmation}?booking_id=$bookingId',
        cancelUrl:  '${AppEnv.siteUrl}${ERoutes.profile}',
      );
      await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
    } catch (_) {}
  }

  bool canCancel(BookingModel b) =>
      b.startTime.isAfter(DateTime.now()) &&
      b.status != 'cancelled' &&
      b.status != 'completed';

  bool canResumePayment(BookingModel b) =>
      AppEnv.stripeMode != 'none' &&
      AppEnv.stripePk.isNotEmpty &&
      b.status == 'pending';

  /// Whether the booking is within the no-refund/restricted cancellation window.
  bool isWithinCancellationWindow(BookingModel b) {
    final deadline = b.startTime
        .subtract(Duration(hours: cancellationHours));
    return DateTime.now().isAfter(deadline);
  }
}
