class SubscriptionPlanModel {
  final String id;
  final String name;
  final String? description;
  final int priceCents;
  final String intervalType; // monthly | quarterly | yearly
  final String? stripePriceId;
  final int bookingDiscountPct;
  final List<String> includedServiceIds;
  final List<String> features;
  final int displayOrder;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    this.description,
    required this.priceCents,
    required this.intervalType,
    this.stripePriceId,
    required this.bookingDiscountPct,
    required this.includedServiceIds,
    required this.features,
    required this.displayOrder,
  });

  double get priceAmount => priceCents / 100;

  String get formattedPrice {
    final dollars = priceCents ~/ 100;
    final cents   = priceCents % 100;
    final amount  = cents == 0 ? '\$$dollars' : '\$$dollars.${cents.toString().padLeft(2, '0')}';
    return '$amount / $intervalType';
  }

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> map) => SubscriptionPlanModel(
    id:                  map['id']           as String,
    name:                map['name']         as String,
    description:         map['description']  as String?,
    priceCents:          (map['price_cents'] as num).toInt(),
    intervalType:        map['interval_type'] as String? ?? 'monthly',
    stripePriceId:       map['stripe_price_id'] as String?,
    bookingDiscountPct:  (map['booking_discount_pct'] as num?)?.toInt() ?? 0,
    includedServiceIds:  (map['included_service_ids'] as List?)?.cast<String>() ?? [],
    features:            (map['features'] as List?)?.cast<String>() ?? [],
    displayOrder:        (map['display_order'] as num?)?.toInt() ?? 0,
  );
}
