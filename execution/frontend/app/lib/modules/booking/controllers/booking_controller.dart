import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_env.dart';
import '../../../core/router/app_router.dart';
import '../models/artist_model.dart';
import '../models/booking_model.dart';
import '../models/package_model.dart';
import '../models/service_model.dart';
import '../models/time_slot_model.dart';
import '../repositories/booking_repository.dart';
import 'booking_addons_controller.dart';

class BookingController extends GetxController {
  final BookingRepository _repository = Get.find<BookingRepository>();

  // ── Loading / error ──────────────────────────────────────────────────────
  final isLoading     = false.obs;
  final slotsLoading  = false.obs;
  final isConfirming  = false.obs;
  final error         = RxnString();

  // ── Step tracking ────────────────────────────────────────────────────────
  final currentStep = 0.obs;

  // ── Path A / B ───────────────────────────────────────────────────────────
  final isAnyArtist = false.obs;

  // ── Selections ───────────────────────────────────────────────────────────
  final selectedArtist    = Rxn<ArtistModel>();
  final selectedServiceIds = <String>[].obs;
  final selectedSlot      = Rxn<TimeSlotModel>();
  final promoCode         = RxnString();

  // ── Client form ──────────────────────────────────────────────────────────
  final clientName  = ''.obs;
  final clientEmail = ''.obs;
  final clientNotes = ''.obs;

  // ── Packages ─────────────────────────────────────────────────────────────
  final packages          = <PackageModel>[].obs;
  final selectedPackageId = RxnString();

  // ── Loaded data ──────────────────────────────────────────────────────────
  final artists          = <ArtistModel>[].obs;
  final services         = <ServiceModel>[].obs;
  final filteredArtists  = <ArtistModel>[].obs;
  final availableSlots   = <TimeSlotModel>[].obs;
  final confirmedBooking = Rxn<BookingModel>();

  // ── Location (LOCATIONS_ENABLED) ─────────────────────────────────────────
  // null = not yet selected (shows LocationSelectorStep when locationsEnabled)
  final selectedLocationId = RxnString();

  void selectLocation(String id) {
    selectedLocationId.value = id;
    // TODO v2: re-filter artists to those assigned to this location
    // once get_artists_for_services RPC returns location_id.
  }

  // ── Referral ──────────────────────────────────────────────────────────────
  final _referralCode = RxnString();

  // ── Waitlist ──────────────────────────────────────────────────────────────
  final waitlistSubmitted  = false.obs;
  final isJoiningWaitlist  = false.obs;
  final waitlistError      = RxnString();

  // ── Date picker ──────────────────────────────────────────────────────────
  final selectedDateIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    _handleStripeCancelReturn();
    _applyBookAgainArgs();
    _captureReferralCode();
  }

  void _captureReferralCode() {
    final code = Get.parameters['ref'];
    if (code != null && code.isNotEmpty) _referralCode.value = code;
  }

  // Called when Stripe redirects back to /booking?cancelled_booking_id=<id>.
  // Silently cancels the pending (unpaid) booking so the slot is released immediately.
  Future<void> _handleStripeCancelReturn() async {
    final id = Get.parameters['cancelled_booking_id'];
    if (id == null || id.isEmpty) return;
    try {
      await _repository.cancelPendingBooking(id);
    } catch (_) {
      // Best-effort — expire-pending-bookings cron is the fallback.
    }
  }

  Future<void> _loadInitialData() async {
    isLoading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _repository.getArtists(),
        _repository.getServices(),
      ]);
      artists.value  = results[0] as List<ArtistModel>;
      services.value = results[1] as List<ServiceModel>;
    } catch (e) {
      error.value = 'Failed to load booking data. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Computed ─────────────────────────────────────────────────────────────
  int get totalDurationMinutes => selectedServiceIds.fold(0, (sum, id) {
        final svc = services.firstWhereOrNull((s) => s.id == id);
        return sum + (svc?.durationMinutes ?? 0);
      });

  double get totalPrice {
    final pkg = selectedPackageId.value != null
        ? packages.firstWhereOrNull((p) => p.id == selectedPackageId.value)
        : null;
    if (pkg != null) return pkg.effectivePrice(services);
    return selectedServiceIds.fold(0.0, (sum, id) {
      final svc = services.firstWhereOrNull((s) => s.id == id);
      return sum + (svc?.price ?? 0.0);
    });
  }

  String get formattedTotalDuration {
    final mins = totalDurationMinutes;
    if (mins == 0) return '—';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h == 0) return '${m}min';
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  List<ServiceModel> get availableServices {
    if (isAnyArtist.value) return services;
    final artist = selectedArtist.value;
    if (artist == null) return services;
    return services
        .where((s) => artist.offeredServiceIds.contains(s.id))
        .toList();
  }

  List<ServiceModel> get selectedServices =>
      services.where((s) => selectedServiceIds.contains(s.id)).toList();

  bool get canProceedStep1 => isAnyArtist.value || selectedArtist.value != null;

  bool get canProceedStep2 =>
      selectedServiceIds.isNotEmpty &&
      (!isAnyArtist.value ||
          filteredArtists.any((a) => a.id == selectedArtist.value?.id));

  bool get canProceedStep3 => selectedSlot.value != null;

  bool get canConfirm =>
      clientName.value.trim().length >= 2 &&
      clientEmail.value.contains('@') &&
      clientEmail.value.contains('.');

  // ── Step 1 — Artist selection ─────────────────────────────────────────────
  void selectArtist(ArtistModel artist) {
    isAnyArtist.value    = false;
    selectedArtist.value = artist;
  }

  void selectAnyArtist() {
    isAnyArtist.value    = true;
    selectedArtist.value = null;
  }

  void proceedFromStep1() {
    if (!canProceedStep1) return;
    selectedServiceIds.clear();
    selectedSlot.value = null;
    filteredArtists.clear();
    currentStep.value = 1;
  }

  // ── Step 2 — Service selection ────────────────────────────────────────────
  void toggleService(String serviceId) {
    clearPackage(); // customizing services deselects the package
    if (selectedServiceIds.contains(serviceId)) {
      selectedServiceIds.remove(serviceId);
    } else {
      selectedServiceIds.add(serviceId);
    }
    if (isAnyArtist.value) {
      _refreshFilteredArtists();
      if (selectedArtist.value != null &&
          !filteredArtists.any((a) => a.id == selectedArtist.value!.id)) {
        selectedArtist.value = null;
      }
    }
    selectedSlot.value = null;
  }

  void selectPackage(PackageModel pkg) {
    selectedPackageId.value  = pkg.id;
    selectedServiceIds.value = List.from(pkg.serviceIds);
    selectedSlot.value       = null;
  }

  void clearPackage() {
    selectedPackageId.value = null;
  }

  Future<void> _refreshFilteredArtists() async {
    try {
      filteredArtists.value =
          await _repository.getArtistsForServices(selectedServiceIds);
    } catch (_) {
      filteredArtists.value = [];
    }
  }

  void selectFilteredArtist(ArtistModel artist) {
    selectedArtist.value = artist;
  }

  Future<void> proceedFromStep2() async {
    if (!canProceedStep2) return;
    selectedSlot.value = null;
    await _loadSlots();
    // Load packages for the selected artist (or all if any-artist flow)
    try {
      packages.value = await _repository.getPackages(
        artistId: selectedArtist.value?.id,
      );
    } catch (_) {
      packages.value = [];
    }
    currentStep.value = 2;
  }

  // ── Step 3 — Time slot selection ──────────────────────────────────────────
  Future<void> _loadSlots() async {
    final artistId = selectedArtist.value?.id;
    if (artistId == null) return;
    slotsLoading.value = true;
    try {
      availableSlots.value = await _repository.getAvailableSlots(
        artistId: artistId,
        requiredDurationMinutes: totalDurationMinutes,
      );
    } catch (_) {
      availableSlots.value = [];
    } finally {
      slotsLoading.value = false;
      selectedDateIndex.value = 0;
    }
  }

  List<TimeSlotModel> get slotsForSelectedDate {
    final allDates = availableDates;
    if (allDates.isEmpty) return [];
    final date = allDates[selectedDateIndex.value];
    return availableSlots
        .where((s) =>
            s.startTime.year  == date.year &&
            s.startTime.month == date.month &&
            s.startTime.day   == date.day)
        .toList();
  }

  List<DateTime> get availableDates {
    final seen  = <String>{};
    final dates = <DateTime>[];
    for (final slot in availableSlots) {
      final key =
          '${slot.startTime.year}-${slot.startTime.month}-${slot.startTime.day}';
      if (seen.add(key)) {
        dates.add(DateTime(
            slot.startTime.year, slot.startTime.month, slot.startTime.day));
      }
    }
    return dates;
  }

  void selectDate(int index) => selectedDateIndex.value = index;
  void selectSlot(TimeSlotModel slot) => selectedSlot.value = slot;

  void proceedFromStep3() {
    if (!canProceedStep3) return;
    currentStep.value = 3;
  }

  // ── Waitlist ──────────────────────────────────────────────────────────────
  Future<void> joinWaitlist({
    required String name,
    required String email,
    DateTime? preferredDate,
  }) async {
    final artist = selectedArtist.value;
    if (artist == null) return;
    isJoiningWaitlist.value = true;
    waitlistError.value = null;
    try {
      await _repository.joinWaitlist(
        artistId:     artist.id,
        serviceIds:   List.from(selectedServiceIds),
        clientName:   name.trim(),
        clientEmail:  email.trim(),
        preferredDate: preferredDate,
      );
      waitlistSubmitted.value = true;
    } catch (_) {
      waitlistError.value = 'Could not join waitlist. Please try again.';
    } finally {
      isJoiningWaitlist.value = false;
    }
  }

  // ── Step 4 — Confirm ──────────────────────────────────────────────────────
  Future<void> confirmBooking() async {
    if (!canConfirm || isConfirming.value) return;
    final artist = selectedArtist.value!;
    final slot   = selectedSlot.value!;
    final addons = Get.find<BookingAddonsController>();

    isConfirming.value = true;
    error.value = null;
    try {
      final notes         = clientNotes.value.trim();
      final phone         = addons.smsPhone.value.trim();
      final useStripe     = AppEnv.stripeMode != 'none' && AppEnv.stripePk.isNotEmpty;
      final noPaymentNow  = !addons.isPaymentRequired; // deposit_pct == 0 → pay at appointment

      confirmedBooking.value = await _repository.confirmBooking(
        artistId:             artist.id,
        serviceIds:           List.from(selectedServiceIds),
        serviceNames:         selectedServices.map((s) => s.name).toList(),
        startTime:            slot.startTime,
        totalDurationMinutes: totalDurationMinutes,
        totalPrice:           totalPrice,
        clientName:           clientName.value.trim(),
        clientEmail:          clientEmail.value.trim(),
        promoCodeId:          promoCode.value,
        clientNotes:          notes.isEmpty ? null : notes,
        clientPhone:          phone.isEmpty ? null : phone,
        locationId:           selectedLocationId.value,
        initialStatus:        (useStripe && !noPaymentNow) ? 'pending' : 'confirmed',
      );
      final booking = confirmedBooking.value!;

      // Record referral if a ref code was present in the URL
      final refCode = _referralCode.value;
      if (refCode != null && refCode.isNotEmpty) {
        try {
          await _repository.recordReferral(
            referralCode:  refCode,
            referredEmail: clientEmail.value.trim(),
            bookingId:     booking.id,
          );
        } catch (_) {
          // Best-effort — don't fail the booking if referral recording fails
        }
      }

      if (!useStripe || noPaymentNow) {
        Get.offAllNamed(ERoutes.confirmation, arguments: booking);
        return;
      }

      // Fully covered by gift/loyalty — no Stripe charge needed
      final charge = addons.chargeAmount(booking.totalPrice);
      if (charge == 0) {
        await _repository.applyFullDiscount(
          bookingId:           booking.id,
          giftVoucherCode:     addons.giftVoucherId.value != null
              ? addons.giftVoucherCode.value
              : null,
          loyaltyPointsRedeem: addons.loyaltyRedeemPoints.value,
        );
        Get.offAllNamed(ERoutes.confirmation, arguments: booking);
        return;
      }

      // Partial discount or no discount — Stripe Checkout
      final checkoutUrl = await _repository.createCheckoutSession(
        bookingId:           booking.id,
        successUrl:          '${AppEnv.siteUrl}${ERoutes.confirmation}?booking_id=${booking.id}',
        cancelUrl:           '${AppEnv.siteUrl}${ERoutes.booking}?cancelled_booking_id=${booking.id}',
        giftVoucherCode:     addons.giftVoucherId.value != null
            ? addons.giftVoucherCode.value
            : null,
        loyaltyPointsRedeem: addons.loyaltyRedeemPoints.value,
        tipAmountCents:      addons.tipAmountCents.value,
      );
      await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.platformDefault);
    } catch (_) {
      error.value = 'Booking failed. The slot may have just been taken.';
    } finally {
      isConfirming.value = false;
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void goBack() {
    if (currentStep.value > 0) currentStep.value--;
  }

  void closeBooking() {
    reset();
    Get.offAllNamed(ERoutes.home);
  }

  void reset() {
    currentStep.value       = 0;
    isAnyArtist.value       = false;
    selectedArtist.value    = null;
    selectedServiceIds.clear();
    selectedSlot.value      = null;
    filteredArtists.clear();
    availableSlots.clear();
    clientName.value        = '';
    clientEmail.value       = '';
    clientNotes.value       = '';
    promoCode.value         = null;
    confirmedBooking.value  = null;
    selectedDateIndex.value = 0;
    error.value             = null;
    waitlistSubmitted.value  = false;
    waitlistError.value      = null;
    selectedPackageId.value  = null;
    packages.clear();
    _referralCode.value     = null;
    Get.find<BookingAddonsController>().reset();
  }

  // ── Book Again ────────────────────────────────────────────────────────────
  /// Pre-selects artist + services from route arguments, then skips to step 2.
  /// Called in onInit after initial data load.
  void _applyBookAgainArgs() {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args == null) return;
    final artistId   = args['artistId']   as String?;
    final serviceIds = args['serviceIds'] as List?;
    if (artistId == null || serviceIds == null) return;

    // Wait for artists to finish loading, then pre-select
    ever(isLoading, (bool loading) {
      if (loading) return;
      final artist = artists.firstWhereOrNull((a) => a.id == artistId);
      if (artist == null) return;
      selectedArtist.value    = artist;
      isAnyArtist.value       = false;
      selectedServiceIds.value = List<String>.from(serviceIds);
      currentStep.value       = 2;
      _loadSlots();
    });
  }
}
