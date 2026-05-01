class ReferralModel {
  final String id;
  final String referralCode;
  final String referrerId;
  final String referredEmail;
  final String? bookingId;
  final DateTime? rewardedAt;
  final String? referrerPromoCode;
  final String? referredPromoCode;
  final DateTime createdAt;

  const ReferralModel({
    required this.id,
    required this.referralCode,
    required this.referrerId,
    required this.referredEmail,
    this.bookingId,
    this.rewardedAt,
    this.referrerPromoCode,
    this.referredPromoCode,
    required this.createdAt,
  });

  bool get isRewarded => rewardedAt != null;

  factory ReferralModel.fromMap(Map<String, dynamic> map) => ReferralModel(
    id:                  map['id']             as String,
    referralCode:        map['referral_code']   as String,
    referrerId:          map['referrer_id']     as String,
    referredEmail:       map['referred_email']  as String,
    bookingId:           map['booking_id']      as String?,
    rewardedAt:          map['rewarded_at'] != null
        ? DateTime.parse(map['rewarded_at'] as String).toLocal()
        : null,
    referrerPromoCode:   map['referrer_promo_code'] as String?,
    referredPromoCode:   map['referred_promo_code'] as String?,
    createdAt:           DateTime.parse(map['created_at'] as String).toLocal(),
  );
}
