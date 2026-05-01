import 'package:intl/intl.dart';

class ShopOrderModel {
  const ShopOrderModel({
    required this.id,
    required this.clientEmail,
    required this.clientName,
    required this.status,
    required this.subtotalCents,
    required this.discountCents,
    required this.totalCents,
    this.discountCode,
    required this.createdAt,
    this.items,
  });

  final String                  id;
  final String                  clientEmail;
  final String                  clientName;
  final String                  status;
  final int                     subtotalCents;
  final int                     discountCents;
  final int                     totalCents;
  final String?                 discountCode;
  final DateTime                createdAt;
  final List<ShopOrderItemModel>? items;

  static final _fmt = NumberFormat.simpleCurrency(decimalDigits: 2);

  double get total          => totalCents / 100;
  String get formattedTotal => _fmt.format(total);
  bool   get isPaid         =>
      ['paid', 'processing', 'shipped', 'delivered'].contains(status);

  factory ShopOrderModel.fromJson(Map<String, dynamic> json) => ShopOrderModel(
        id:            json['id'] as String,
        clientEmail:   json['client_email'] as String,
        clientName:    json['client_name'] as String,
        status:        json['status'] as String,
        subtotalCents: json['subtotal_cents'] as int,
        discountCents: json['discount_cents'] as int? ?? 0,
        totalCents:    json['total_cents'] as int,
        discountCode:  json['discount_code'] as String?,
        createdAt:     DateTime.parse(json['created_at'] as String),
        items: (json['shop_order_items'] as List?)
            ?.map((i) => ShopOrderItemModel.fromJson(i as Map<String, dynamic>))
            .toList(),
      );
}

class ShopOrderItemModel {
  const ShopOrderItemModel({
    required this.id,
    required this.productName,
    required this.priceCents,
    required this.quantity,
  });

  final String id;
  final String productName;
  final int    priceCents;
  final int    quantity;

  int get subtotalCents => priceCents * quantity;

  factory ShopOrderItemModel.fromJson(Map<String, dynamic> json) =>
      ShopOrderItemModel(
        id:          json['id'] as String,
        productName: json['product_name'] as String,
        priceCents:  json['price_cents'] as int,
        quantity:    json['quantity'] as int,
      );
}
