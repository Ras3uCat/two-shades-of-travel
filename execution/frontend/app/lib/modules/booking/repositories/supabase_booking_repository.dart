import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/artist_model.dart';
import '../models/booking_model.dart';
import '../models/package_model.dart';
import '../models/service_model.dart';
import '../models/time_slot_model.dart';
import 'booking_repository.dart';

/// SupabaseBookingRepository — production implementation backed by Supabase.
/// All slot generation happens server-side via Postgres functions.
class SupabaseBookingRepository implements BookingRepository {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<List<ArtistModel>> getArtists() async {
    final rows = await _db
        .from('profiles')
        .select('id, display_name, bio, photo_url, specialties, role')
        .inFilter('role', ['master', 'staff'])
        .order('display_name');

    // Fetch each artist's service IDs in one query via artist_services
    final profileIds = (rows as List).map((r) => r['id'] as String).toList();
    if (profileIds.isEmpty) return [];

    final serviceLinks = await _db
        .from('artist_services')
        .select('artist_id, service_id')
        .inFilter('artist_id', profileIds);

    final serviceMap = <String, List<String>>{};
    for (final link in serviceLinks as List) {
      (serviceMap[link['artist_id'] as String] ??= [])
          .add(link['service_id'] as String);
    }

    return rows.map<ArtistModel>((r) {
      final map = Map<String, dynamic>.from(r as Map);
      map['service_ids'] = serviceMap[r['id'] as String] ?? [];
      return ArtistModel.fromMap(map);
    }).toList();
  }

  @override
  Future<List<ServiceModel>> getServices() async {
    final rows = await _db
        .from('services')
        .select()
        .eq('is_active', true)
        .order('category')
        .order('name');
    return (rows as List).map((r) => ServiceModel.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ServiceModel>> getServicesForArtist(String artistId) async {
    final links = await _db
        .from('artist_services')
        .select('service_id')
        .eq('artist_id', artistId);

    final ids = (links as List).map((l) => l['service_id'] as String).toList();
    if (ids.isEmpty) return [];

    final rows = await _db
        .from('services')
        .select()
        .inFilter('id', ids)
        .eq('is_active', true);
    return (rows as List).map((r) => ServiceModel.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ArtistModel>> getArtistsForServices(List<String> serviceIds) async {
    if (serviceIds.isEmpty) return getArtists();

    // Server-side: use Postgres function that returns artists offering ALL ids
    final rows = await _db.rpc('get_artists_for_services', params: {
      'p_service_ids': serviceIds,
    }) as List;

    final profileIds = rows.map((r) => r['id'] as String).toList();
    if (profileIds.isEmpty) return [];

    final serviceLinks = await _db
        .from('artist_services')
        .select('artist_id, service_id')
        .inFilter('artist_id', profileIds);

    final serviceMap = <String, List<String>>{};
    for (final link in serviceLinks as List) {
      (serviceMap[link['artist_id'] as String] ??= [])
          .add(link['service_id'] as String);
    }

    return rows.map<ArtistModel>((r) {
      final map = Map<String, dynamic>.from(r as Map);
      map['service_ids'] = serviceMap[r['id'] as String] ?? [];
      return ArtistModel.fromMap(map);
    }).toList();
  }

  @override
  Future<List<TimeSlotModel>> getAvailableSlots({
    required String artistId,
    required int requiredDurationMinutes,
    int daysAhead = 14,
  }) async {
    final now  = DateTime.now().toUtc();
    final end  = now.add(Duration(days: daysAhead));

    final rows = await _db.rpc('get_available_slots', params: {
      'p_artist_id':              artistId,
      'p_date_from':              now.toIso8601String(),
      'p_date_to':                end.toIso8601String(),
      'p_duration_minutes':       requiredDurationMinutes,
    }) as List;

    return rows.map((r) => TimeSlotModel.fromMap(r as Map<String, dynamic>)).toList();
  }

  @override
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
  }) async {
    final result = await _db.rpc('book_appointment', params: {
      'p_artist_id':      artistId,
      'p_service_ids':    serviceIds,
      'p_service_names':  serviceNames,
      'p_start_time':     startTime.toUtc().toIso8601String(),
      'p_total_duration': totalDurationMinutes,
      'p_total_price':    totalPrice,
      'p_client_name':    clientName,
      'p_client_email':   clientEmail,
      'p_promo_code_id':  promoCodeId,
      'p_client_notes':   clientNotes,
      'p_client_phone':   clientPhone,
      'p_initial_status': initialStatus,
    });
    final booking = BookingModel.fromMap(result as Map<String, dynamic>);
    // Store location on the booking row (secondary update — location_id is not in the RPC).
    if (locationId != null) {
      await _db.from('bookings')
          .update({'location_id': locationId})
          .eq('id', booking.id);
    }
    return booking;
  }

  @override
  @override
  Future<String> createCheckoutSession({
    required String bookingId,
    required String successUrl,
    required String cancelUrl,
    String? giftVoucherCode,
    int loyaltyPointsRedeem = 0,
    int tipAmountCents = 0,
  }) async {
    final body = <String, dynamic>{
      'booking_id': bookingId, 'success_url': successUrl, 'cancel_url': cancelUrl,
    };
    if (giftVoucherCode != null && giftVoucherCode.isNotEmpty) body['gift_voucher_code'] = giftVoucherCode;
    if (loyaltyPointsRedeem > 0) body['loyalty_points_redeem'] = loyaltyPointsRedeem;
    if (tipAmountCents > 0) body['tip_amount_cents'] = tipAmountCents;
    final response = await _db.functions.invoke('create-checkout', body: body);
    return response.data['url'] as String;
  }

  @override
  Future<List<BookingModel>> getUserBookings() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];
    final rows = await _db
        .from('bookings')
        .select()
        .eq('client_email', user.email!)
        .order('start_time', ascending: false);
    return (rows as List)
        .map((r) => BookingModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _db.functions.invoke(
      'cancel-booking',
      body: {'booking_id': bookingId},
    );
  }

  @override
  Future<void> cancelPendingBooking(String bookingId) async {
    await _db.functions.invoke(
      'cancel-pending-booking',
      body: {'booking_id': bookingId},
    );
  }

  @override
  Future<Map<String, dynamic>> getBookingConfig() async {
    final row = await _db
        .from('business_config')
        .select('deposit_pct, loyalty_cents_per_point, loyalty_min_redeem')
        .limit(1)
        .single();
    return row;
  }

  @override
  Future<Map<String, dynamic>?> validateGiftVoucher(String code) async {
    final rows = await _db
        .from('gift_vouchers')
        .select('id, amount_cents')
        .eq('code', code)
        .isFilter('redeemed_at', null)
        .gt('expires_at', DateTime.now().toIso8601String())
        .limit(1);
    if ((rows as List).isEmpty) return null;
    return rows.first;
  }

  @override
  Future<void> applyFullDiscount({
    required String bookingId,
    String? giftVoucherCode,
    int loyaltyPointsRedeem = 0,
  }) async {
    await _db.functions.invoke(
      'apply-gift-voucher',
      body: {
        'booking_id':         bookingId,
        // ignore: use_null_aware_elements
        if (giftVoucherCode != null) 'gift_voucher_code': giftVoucherCode,
        if (loyaltyPointsRedeem > 0) 'loyalty_points_redeem': loyaltyPointsRedeem,
      },
    );
  }

  @override
  Future<void> joinWaitlist({
    required String artistId,
    required List<String> serviceIds,
    required String clientName,
    required String clientEmail,
    DateTime? preferredDate,
  }) async {
    await _db.from('waitlist').insert({
      'artist_id': artistId, 'service_ids': serviceIds,
      'client_name': clientName, 'client_email': clientEmail,
      if (preferredDate != null)
        'preferred_date': preferredDate.toIso8601String().substring(0, 10),
    });
  }

  @override
  Future<List<PackageModel>> getPackages({String? artistId}) async {
    var q = _db.from('packages').select().eq('is_active', true);
    if (artistId != null) {
      q = q.or('artist_id.is.null,artist_id.eq.$artistId');
    }
    final rows = await q.order('display_order');
    return (rows as List)
        .map((r) => PackageModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> getLoyaltyBalance(String email) async {
    final rows = await _db
        .from('loyalty_ledger')
        .select('points')
        .eq('client_email', email.toLowerCase());
    final total = (rows as List).fold<int>(0,
        (sum, r) => sum + ((r['points'] as num).toInt()));
    return total < 0 ? 0 : total;
  }
  @override
  Future<Map<String, dynamic>> createRecurringSeries({
    required String templateBookingId,
    required int intervalDays,
    required DateTime endDate,
    bool confirmed = true,
  }) async {
    final result = await _db.rpc('create_recurring_series', params: {
      'p_template_booking_id': templateBookingId,
      'p_interval_days':       intervalDays,
      'p_end_date':            endDate.toIso8601String().substring(0, 10),
      'p_confirmed':           confirmed,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  @override
  Future<void> cancelRecurringSeries(String seriesId) async =>
      _db.rpc('cancel_recurring_series', params: {'p_series_id': seriesId});

  @override
  Future<void> recordReferral({
    required String referralCode,
    required String referredEmail,
    required String bookingId,
  }) async {
    await _db.rpc('record_referral', params: {
      'p_referral_code':  referralCode,
      'p_referred_email': referredEmail,
      'p_booking_id':     bookingId,
    });
  }
}
