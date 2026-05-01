class SubscriptionModel {
  final String id;
  final String planId;
  final String clientEmail;
  final String clientName;
  final String? stripeSubscriptionId;
  final String status; // active | trialing | past_due | cancelled
  final DateTime? currentPeriodEnd;
  final DateTime createdAt;

  const SubscriptionModel({
    required this.id,
    required this.planId,
    required this.clientEmail,
    required this.clientName,
    this.stripeSubscriptionId,
    required this.status,
    this.currentPeriodEnd,
    required this.createdAt,
  });

  bool get isActive => status == 'active' || status == 'trialing';

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) => SubscriptionModel(
    id:                    map['id']          as String,
    planId:                map['plan_id']     as String,
    clientEmail:           map['client_email'] as String,
    clientName:            map['client_name']  as String,
    stripeSubscriptionId:  map['stripe_subscription_id'] as String?,
    status:                map['status'] as String? ?? 'active',
    currentPeriodEnd:      map['current_period_end'] != null
        ? DateTime.parse(map['current_period_end'] as String).toLocal()
        : null,
    createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
  );
}
