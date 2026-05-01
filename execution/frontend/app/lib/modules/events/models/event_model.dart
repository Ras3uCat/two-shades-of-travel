import 'package:intl/intl.dart';

class EventModel {
  final String  id;
  final String  title;
  final String  slug;
  final String? description;
  final DateTime eventDate;
  final String? venue;
  final String? heroImageUrl;
  final int     capacity;
  final String  status;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.eventDate,
    this.venue,
    this.heroImageUrl,
    required this.capacity,
    required this.status,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> j) => EventModel(
    id:           j['id']           as String,
    title:        j['title']        as String,
    slug:         j['slug']         as String,
    description:  j['description']  as String?,
    eventDate:    DateTime.parse(j['event_date'] as String).toLocal(),
    venue:        j['venue']        as String?,
    heroImageUrl: j['hero_image_url'] as String?,
    capacity:     (j['capacity']    as num).toInt(),
    status:       j['status']       as String,
    createdAt:    DateTime.parse(j['created_at'] as String),
  );

  bool get isPublished  => status == 'published';
  bool get isCancelled  => status == 'cancelled';
  bool get isDraft      => status == 'draft';

  String get formattedDate =>
      DateFormat('EEEE, MMMM d, yyyy · h:mm a').format(eventDate);

  String get formattedDateShort =>
      DateFormat('MMM d, yyyy').format(eventDate);
}
