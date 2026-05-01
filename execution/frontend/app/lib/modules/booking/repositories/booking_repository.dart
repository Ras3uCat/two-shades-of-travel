import '../models/artist_model.dart';
import '../models/booking_model.dart';
import '../models/package_model.dart';
import '../models/service_model.dart';
import '../models/time_slot_model.dart';

/// BookingRepository — async interface for all booking data operations.
/// The Supabase implementation is injected via GetX. Swap for a mock in tests.
abstract class BookingRepository {
  Future<List<ArtistModel>> getArtists();

  Future<List<ServiceModel>> getServices();

  Future<List<ServiceModel>> getServicesForArtist(String artistId);

  /// Returns artists who offer ALL of the given service IDs.
  Future<List<ArtistModel>> getArtistsForServices(List<String> serviceIds);

  /// Returns available + booked slots for an artist over the next [daysAhead] days.
  /// The Postgres function filters out slots shorter than [requiredDurationMinutes].
  Future<List<TimeSlotModel>> getAvailableSlots({
    required String artistId,
    required int requiredDurationMinutes,
    int daysAhead = 14,
  });

  /// Calls the `book_appointment` Postgres function (FOR UPDATE row lock).
  /// Returns the confirmed booking.
  /// [initialStatus] is 'pending' when Stripe payment is required, 'confirmed' otherwise.
  Future<BookingModel> confirmBooking({
    required String artistId,
    required List<String> serviceIds,
    required List<String> serviceNames,
    required DateTime startTime,
    required int totalDurationMinutes,
    required double totalPrice,
    required String clientName,
    required String clientEmail,
    String? promoCodeId,
    String? clientNotes,
    String? clientPhone,
    String? locationId,
    String initialStatus = 'confirmed',
  });

  /// Creates a Stripe Checkout session for a pending booking.
  /// Returns the Stripe-hosted checkout URL.
  Future<String> createCheckoutSession({
    required String bookingId,
    required String successUrl,
    required String cancelUrl,
    String? giftVoucherCode,
    int loyaltyPointsRedeem,
    int tipAmountCents = 0,
  });

  /// Returns all bookings for the currently authenticated user (by email).
  Future<List<BookingModel>> getUserBookings();

  /// Cancels a booking owned by the current user.
  /// RLS enforces the booking must be upcoming and not already cancelled/completed.
  Future<void> cancelBooking(String bookingId);

  /// Cancels a booking that is still in 'pending' status (Stripe payment abandoned).
  /// No auth required — safe because only unpaid pending rows are affected.
  Future<void> cancelPendingBooking(String bookingId);

  /// Returns deposit_pct, loyalty_cents_per_point, loyalty_min_redeem from business_config.
  Future<Map<String, dynamic>> getBookingConfig();

  /// Validates a gift voucher code. Returns {id, amount_cents} or null if invalid/expired.
  Future<Map<String, dynamic>?> validateGiftVoucher(String code);

  /// Confirms a booking that is fully covered by gift/loyalty (no Stripe charge needed).
  Future<void> applyFullDiscount({
    required String bookingId,
    String? giftVoucherCode,
    int loyaltyPointsRedeem,
  });

  /// Returns the total loyalty points balance for an email address.
  Future<int> getLoyaltyBalance(String email);

  /// Returns active packages, optionally filtered to an artist.
  Future<List<PackageModel>> getPackages({String? artistId});

  /// Adds a client to the waitlist for a given artist.
  Future<void> joinWaitlist({
    required String artistId,
    required List<String> serviceIds,
    required String clientName,
    required String clientEmail,
    DateTime? preferredDate,
  });

  /// Creates a recurring series from a confirmed booking.
  /// Returns a map with keys: series_id (String), created (int), conflicts (List of date strings).
  /// [confirmed] is false when Stripe payment is required (bookings created as pending).
  Future<Map<String, dynamic>> createRecurringSeries({
    required String templateBookingId,
    required int intervalDays,
    required DateTime endDate,
    bool confirmed = true,
  });

  /// Cancels all future confirmed bookings in a series.
  Future<void> cancelRecurringSeries(String seriesId);

  /// Records a referral after a booking is confirmed. Best-effort — errors are swallowed by the caller.
  Future<void> recordReferral({
    required String referralCode,
    required String referredEmail,
    required String bookingId,
  });
}
