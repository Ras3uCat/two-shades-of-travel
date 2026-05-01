import 'package:get/get.dart';
import '../../booking/models/booking_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/calendar_token_repository.dart';

/// StaffController — data + actions for the staff portal.
/// Scoped entirely to the currently authenticated staff member.
class StaffController extends GetxController {
  final AdminRepository _repo = Get.find<AdminRepository>();

  String get _artistId => Get.find<AuthController>().user!.id;

  // ── State ─────────────────────────────────────────────────────────────────
  final isLoading = false.obs;
  final error     = RxnString();

  // ── Bookings ──────────────────────────────────────────────────────────────
  final bookings = <BookingModel>[].obs;

  // ── Calendar token ────────────────────────────────────────────────────────
  final calendarToken    = RxnString();
  final isCalendarLoading = false.obs;

  // ── Time-off ──────────────────────────────────────────────────────────────
  final timeOff = <Map<String, dynamic>>[].obs;

  // ── Promo codes ───────────────────────────────────────────────────────────
  final promoCodes = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  Future<void> _loadAll() async {
    isLoading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _repo.getBookings(artistId: _artistId),
        _repo.getTimeOff(_artistId),
        _repo.getPromoCodes(_artistId),
      ]);
      bookings.value   = results[0] as List<BookingModel>;
      timeOff.value    = results[1] as List<Map<String, dynamic>>;
      promoCodes.value = results[2] as List<Map<String, dynamic>>;
    } catch (e) {
      error.value = 'Failed to load your data.';
    } finally {
      isLoading.value = false;
    }
    loadCalendarToken();
  }

  Future<void> loadCalendarToken() async {
    isCalendarLoading.value = true;
    try {
      final repo = Get.find<CalendarTokenRepository>();
      calendarToken.value = await repo.ensureToken(_artistId);
    } catch (_) {
    } finally {
      isCalendarLoading.value = false;
    }
  }

  Future<void> regenerateCalendarToken() async {
    try {
      final repo = Get.find<CalendarTokenRepository>();
      calendarToken.value = await repo.regenerateToken(_artistId);
    } catch (_) {}
  }

  // ── Time-off ──────────────────────────────────────────────────────────────
  Future<bool> addTimeOff({
    required DateTime start,
    required DateTime end,
    String? reason,
  }) async {
    try {
      await _repo.addTimeOff(
          artistId: _artistId, start: start, end: end, reason: reason);
      timeOff.value = await _repo.getTimeOff(_artistId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteTimeOff(String id) async {
    await _repo.deleteTimeOff(id);
    timeOff.value = await _repo.getTimeOff(_artistId);
  }

  // ── Promo codes ───────────────────────────────────────────────────────────
  Future<bool> createPromoCode({
    required String code,
    required String discountType,
    required double discountValue,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    try {
      await _repo.createPromoCode({
        'code':           code.toUpperCase().trim(),
        'artist_id':      _artistId,
        'discount_type':  discountType,
        'discount_value': discountValue,
        'max_uses':   maxUses,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
      });
      promoCodes.value = await _repo.getPromoCodes(_artistId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> togglePromoCode(String id, bool isActive) async {
    await _repo.togglePromoCode(id, isActive);
    promoCodes.value = await _repo.getPromoCodes(_artistId);
  }

  Future<void> deletePromoCode(String id) async {
    await _repo.deletePromoCode(id);
    promoCodes.value = await _repo.getPromoCodes(_artistId);
  }

  // ── Computed ──────────────────────────────────────────────────────────────
  List<BookingModel> get upcomingBookings => bookings
      .where((b) =>
          b.startTime.isAfter(DateTime.now()) && b.status != 'cancelled')
      .toList();

  List<BookingModel> get pastBookings => bookings
      .where((b) => b.startTime.isBefore(DateTime.now()))
      .toList();
}
