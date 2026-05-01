// Category is a free-form string (e.g. "Hair", "Nails") defined in the DB.
import '../../../core/utils/slugify.dart';

class ServiceModel {
  final String id;
  final String name;
  final String category; // free-form string from DB
  final int durationMinutes;
  final double price;
  final String description;
  final String? imageUrl;

  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.price,
    required this.description,
    this.imageUrl,
    this.isActive = true,
  });

  String get categoryLabel => category.toUpperCase();

  String get slug => slugify(name);

  String get formattedDuration {
    if (durationMinutes < 60) return '${durationMinutes}min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  String get formattedPrice => '\$${price.toStringAsFixed(0)}';

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'Service',
      durationMinutes: (map['duration_minutes'] as num).toInt(),
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  ServiceModel copyWith({
    String? id,
    String? name,
    String? category,
    int? durationMinutes,
    double? price,
    String? description,
    String? imageUrl,
  }) => ServiceModel(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    price: price ?? this.price,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
  );
}
