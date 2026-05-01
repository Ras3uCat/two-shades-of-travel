import 'package:intl/intl.dart';

class BookingModel {
  final String id;
  final String artistId;
  final String artistName;
  final List<String> serviceIds;
  final List<String> serviceNames;
  final int totalDurationMinutes;
  final double totalPrice;
  final DateTime startTime;
  final String clientName;
  final String clientEmail;
  final String? promoCodeId;
  final String? paymentIntentId;
  final String? clientNotes;
  final String? clientPhone;
  final String? giftVoucherId;
  final int loyaltyPointsRedeemed;
  final String status;   // pending | confirmed | cancelled | completed
  final DateTime createdAt;
  final String? reviewToken;
  final String? recurringSeriesId;
  final String? stripeInvoiceId;
  final String? stripeInvoiceUrl;
  final DateTime? invoiceSentAt;
  final String? invoiceNumber;

  const BookingModel({
    required this.id,
    required this.artistId,
    required this.artistName,
    required this.serviceIds,
    required this.serviceNames,
    required this.totalDurationMinutes,
    required this.totalPrice,
    required this.startTime,
    required this.clientName,
    required this.clientEmail,
    this.promoCodeId,
    this.paymentIntentId,
    this.clientNotes,
    this.clientPhone,
    this.giftVoucherId,
    this.loyaltyPointsRedeemed = 0,
    this.status = 'pending',
    required this.createdAt,
    this.reviewToken,
    this.recurringSeriesId,
    this.stripeInvoiceId,
    this.stripeInvoiceUrl,
    this.invoiceSentAt,
    this.invoiceNumber,
  });

  DateTime get endTime =>
      startTime.add(Duration(minutes: totalDurationMinutes));

  String get formattedDate =>
      DateFormat('EEE, MMM d, yyyy').format(startTime);

  String get formattedTime =>
      DateFormat('h:mm a').format(startTime);

  String get formattedEndTime =>
      DateFormat('h:mm a').format(endTime);

  String get formattedDuration {
    final h = totalDurationMinutes ~/ 60;
    final m = totalDurationMinutes % 60;
    if (h == 0) return '${m}min';
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  String get formattedPrice => '\$${totalPrice.toStringAsFixed(0)}';

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id:                   map['id'] as String,
      artistId:             map['artist_id'] as String,
      artistName:           map['artist_name'] as String? ?? '',
      serviceIds:           (map['service_ids'] as List).cast<String>(),
      serviceNames:         (map['service_names'] as List).cast<String>(),
      totalDurationMinutes: (map['total_duration_minutes'] as num).toInt(),
      totalPrice:           (map['total_price'] as num).toDouble(),
      startTime:            DateTime.parse(map['start_time'] as String).toLocal(),
      clientName:           map['client_name'] as String,
      clientEmail:          map['client_email'] as String,
      promoCodeId:            map['promo_code_id'] as String?,
      paymentIntentId:        map['stripe_payment_intent_id'] as String?,
      clientNotes:            map['client_notes'] as String?,
      clientPhone:            map['client_phone'] as String?,
      giftVoucherId:          map['gift_voucher_id'] as String?,
      loyaltyPointsRedeemed:  (map['loyalty_points_redeemed'] as num?)?.toInt() ?? 0,
      status:                 map['status'] as String? ?? 'pending',
      createdAt:              DateTime.parse(map['created_at'] as String).toLocal(),
      reviewToken:            map['review_token'] as String?,
      recurringSeriesId:      map['recurring_series_id'] as String?,
      stripeInvoiceId:        map['stripe_invoice_id'] as String?,
      stripeInvoiceUrl:       map['stripe_invoice_url'] as String?,
      invoiceSentAt:          map['invoice_sent_at'] != null
          ? DateTime.parse(map['invoice_sent_at'] as String).toLocal()
          : null,
      invoiceNumber:          map['invoice_number'] as String?,
    );
  }
}
