import 'package:get/get.dart';
import '../repositories/booking_repository.dart';

/// BookingAddonsController — reactive state for all Step 4 add-on features:
/// deposit display, SMS phone capture, gift voucher validation, and loyalty points.
/// Registered alongside BookingController via BookingBinding.
class BookingAddonsController extends GetxController {
  final BookingRepository _repository = Get.find<BookingRepository>();

  // ── Config (loaded from business_config on init) ──────────────────────────
  final depositPct          = 100.obs;   // 0 = no payment now; 1–99 = partial deposit; 100 = full upfront
  final loyaltyCentsPerPoint = 1.obs;    // 1 point = N cents
  final loyaltyMinRedeem    = 500.obs;   // minimum points needed to redeem

  // ── SMS ───────────────────────────────────────────────────────────────────
  final smsPhone = ''.obs;

  // ── Gift voucher ──────────────────────────────────────────────────────────
  final giftVoucherCode       = ''.obs;
  final giftVoucherId         = RxnString();
  final giftVoucherAmountCents = 0.obs;
  final isValidatingVoucher   = false.obs;
  final voucherError          = RxnString();

  // ── Loyalty ───────────────────────────────────────────────────────────────
  final loyaltyBalance         = 0.obs;   // current points balance for entered email
  final loyaltyRedeemPoints    = 0.obs;   // how many points user chose to redeem
  final isLoadingLoyalty       = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final cfg = await _repository.getBookingConfig();
      depositPct.value           = (cfg['deposit_pct']           as num?)?.toInt() ?? 100;
      loyaltyCentsPerPoint.value = (cfg['loyalty_cents_per_point'] as num?)?.toInt() ?? 1;
      loyaltyMinRedeem.value     = (cfg['loyalty_min_redeem']     as num?)?.toInt() ?? 500;
    } catch (_) {
      // Use defaults — non-fatal
    }
  }

  // ── Gift voucher ──────────────────────────────────────────────────────────

  Future<void> validateGiftVoucher(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      _clearVoucher();
      return;
    }
    isValidatingVoucher.value = true;
    voucherError.value = null;
    try {
      final result = await _repository.validateGiftVoucher(trimmed);
      if (result == null) {
        voucherError.value = 'Invalid or expired voucher code.';
        _clearVoucher();
      } else {
        giftVoucherId.value          = result['id'] as String;
        giftVoucherAmountCents.value = (result['amount_cents'] as num).toInt();
        voucherError.value           = null;
      }
    } catch (_) {
      voucherError.value = 'Could not validate voucher. Try again.';
      _clearVoucher();
    } finally {
      isValidatingVoucher.value = false;
    }
  }

  void _clearVoucher() {
    giftVoucherId.value          = null;
    giftVoucherAmountCents.value = 0;
  }

  // ── Loyalty ───────────────────────────────────────────────────────────────

  Future<void> loadLoyaltyBalance(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      loyaltyBalance.value      = 0;
      loyaltyRedeemPoints.value = 0;
      return;
    }
    isLoadingLoyalty.value = true;
    try {
      loyaltyBalance.value = await _repository.getLoyaltyBalance(email);
    } catch (_) {
      loyaltyBalance.value = 0;
    } finally {
      isLoadingLoyalty.value = false;
    }
  }

  /// Applies max redeemable points toward [totalPrice].
  /// Capped at balance and at what the total costs.
  void applyLoyaltyPoints(double totalPrice) {
    if (loyaltyBalance.value < loyaltyMinRedeem.value) return;
    final maxByBalance = loyaltyBalance.value;
    final maxByTotal   = (totalPrice * 100 / loyaltyCentsPerPoint.value).floor();
    loyaltyRedeemPoints.value = maxByBalance < maxByTotal ? maxByBalance : maxByTotal;
  }

  void clearLoyaltyRedeem() => loyaltyRedeemPoints.value = 0;

  // ── Tip / Gratuity ────────────────────────────────────────────────────────
  final tipAmountCents = 0.obs;

  void setTip(int cents) => tipAmountCents.value = cents;

  double get tipDollars => tipAmountCents.value / 100.0;
  bool get hasTip => tipAmountCents.value > 0;

  // ── Computed ──────────────────────────────────────────────────────────────

  double get giftDiscountDollars => giftVoucherAmountCents.value / 100.0;

  double get loyaltyDiscountDollars =>
      loyaltyRedeemPoints.value * loyaltyCentsPerPoint.value / 100.0;

  /// Total charge after all discounts, plus tip. Never below zero (before tip).
  double chargeAmount(double totalPrice) {
    final discounted = totalPrice - giftDiscountDollars - loyaltyDiscountDollars;
    return (discounted < 0 ? 0 : discounted) + tipDollars;
  }

  /// 0 = no payment at booking (pay at appointment). 1–99 = partial deposit. 100 = full upfront.
  bool get isPaymentRequired => depositPct.value > 0;

  /// True only when a partial deposit row should be shown in the UI (1–99%).
  bool get isDepositEnabled => depositPct.value > 0 && depositPct.value < 100;

  /// Amount due at checkout. Returns 0 when no payment is required (depositPct == 0).
  double depositDue(double totalPrice) {
    if (!isPaymentRequired) return 0;
    final charge = chargeAmount(totalPrice);
    return (charge * depositPct.value / 100 * 100).roundToDouble() / 100;
  }

  bool get hasVoucher => giftVoucherId.value != null;
  bool get hasLoyaltyRedeem => loyaltyRedeemPoints.value > 0;
  bool get hasDiscount => hasVoucher || hasLoyaltyRedeem;

  bool canRedeem(double totalPrice) =>
      loyaltyBalance.value >= loyaltyMinRedeem.value && totalPrice > 0;

  // ── Reset ─────────────────────────────────────────────────────────────────

  void reset() {
    smsPhone.value               = '';
    giftVoucherCode.value        = '';
    giftVoucherId.value          = null;
    giftVoucherAmountCents.value = 0;
    voucherError.value           = null;
    loyaltyBalance.value         = 0;
    loyaltyRedeemPoints.value    = 0;
    tipAmountCents.value         = 0;
  }
}
