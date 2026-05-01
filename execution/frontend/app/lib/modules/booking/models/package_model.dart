import 'package:get/get.dart';
import 'service_model.dart';

/// PackageModel — a bundled deal combining multiple services with a discount.
class PackageModel {
  final String id;
  final String name;
  final String? description;
  final List<String> serviceIds;
  final int discountPct;       // 0–100
  final double? priceOverride; // null = calculated from services × discount
  final String? artistId;      // null = available for all artists
  final int displayOrder;

  const PackageModel({
    required this.id,
    required this.name,
    this.description,
    required this.serviceIds,
    required this.discountPct,
    this.priceOverride,
    this.artistId,
    required this.displayOrder,
  });

  factory PackageModel.fromMap(Map<String, dynamic> map) => PackageModel(
        id:            map['id'] as String,
        name:          map['name'] as String,
        description:   map['description'] as String?,
        serviceIds:    List<String>.from((map['service_ids'] as List?) ?? []),
        discountPct:   (map['discount_pct'] as num?)?.toInt() ?? 0,
        priceOverride: (map['price_override'] as num?)?.toDouble(),
        artistId:      map['artist_id'] as String?,
        displayOrder:  (map['display_order'] as num?)?.toInt() ?? 0,
      );

  /// Effective price given the full list of services in this package.
  double effectivePrice(List<ServiceModel> services) {
    if (priceOverride != null) return priceOverride!;
    final base = serviceIds.fold<double>(0.0, (sum, id) {
      return sum + (services.firstWhereOrNull((s) => s.id == id)?.price ?? 0);
    });
    return base * (1 - discountPct / 100);
  }

  String formattedPrice(List<ServiceModel> services) =>
      '\$${effectivePrice(services).toStringAsFixed(2)}';
}
