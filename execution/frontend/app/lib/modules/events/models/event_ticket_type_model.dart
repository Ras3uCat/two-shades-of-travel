class EventTicketTypeModel {
  final String  id;
  final String  eventId;
  final String  name;
  final String? description;
  final int     priceCents;
  final int     quantityTotal;

  const EventTicketTypeModel({
    required this.id,
    required this.eventId,
    required this.name,
    this.description,
    required this.priceCents,
    required this.quantityTotal,
  });

  factory EventTicketTypeModel.fromJson(Map<String, dynamic> j) =>
      EventTicketTypeModel(
        id:            j['id']             as String,
        eventId:       j['event_id']       as String,
        name:          j['name']           as String,
        description:   j['description']    as String?,
        priceCents:    (j['price_cents']   as num).toInt(),
        quantityTotal: (j['quantity_total'] as num).toInt(),
      );

  bool   get isFree         => priceCents == 0;
  double get price          => priceCents / 100;
  String get formattedPrice => isFree ? 'Free' : '\$${price.toStringAsFixed(2)}';
}
