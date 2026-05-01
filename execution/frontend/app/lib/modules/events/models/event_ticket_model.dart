class EventTicketModel {
  final String    id;
  final String    eventId;
  final String    ticketTypeId;
  final String    buyerName;
  final String    buyerEmail;
  final int       quantity;
  final int       totalCents;
  final String    ticketCode;
  final String    status;
  final DateTime? checkedInAt;
  final DateTime  createdAt;

  const EventTicketModel({
    required this.id,
    required this.eventId,
    required this.ticketTypeId,
    required this.buyerName,
    required this.buyerEmail,
    required this.quantity,
    required this.totalCents,
    required this.ticketCode,
    required this.status,
    this.checkedInAt,
    required this.createdAt,
  });

  factory EventTicketModel.fromJson(Map<String, dynamic> j) => EventTicketModel(
    id:           j['id']            as String,
    eventId:      j['event_id']      as String,
    ticketTypeId: j['ticket_type_id'] as String,
    buyerName:    j['buyer_name']    as String,
    buyerEmail:   j['buyer_email']   as String,
    quantity:     (j['quantity']     as num).toInt(),
    totalCents:   (j['total_cents']  as num).toInt(),
    ticketCode:   j['ticket_code']   as String,
    status:       j['status']        as String,
    checkedInAt:  j['checked_in_at'] != null
        ? DateTime.parse(j['checked_in_at'] as String)
        : null,
    createdAt:    DateTime.parse(j['created_at'] as String),
  );

  bool get isConfirmed => status == 'confirmed';
  bool get isCheckedIn => status == 'checked_in';
  bool get isPending   => status == 'pending';

  /// First 8 chars of the UUID, uppercased — for display at the door.
  String get codeDisplay =>
      ticketCode.replaceAll('-', '').substring(0, 8).toUpperCase();

  double get totalPrice => totalCents / 100;
  String get formattedTotal =>
      totalCents == 0 ? 'Free' : '\$${totalPrice.toStringAsFixed(2)}';
}
