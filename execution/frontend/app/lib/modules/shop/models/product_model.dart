import 'package:intl/intl.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.priceCents,
    this.compareAtPriceCents,
    required this.images,
    this.inventoryCount,
    required this.isActive,
    required this.displayOrder,
    required this.tags,
  });

  final String       id;
  final String?      categoryId;
  final String       name;
  final String?      description;
  final int          priceCents;
  final int?         compareAtPriceCents;
  final List<String> images;
  final int?         inventoryCount; // null = unlimited
  final bool         isActive;
  final int          displayOrder;
  final List<String> tags;

  static final _fmt = NumberFormat.simpleCurrency(decimalDigits: 0);

  double  get price              => priceCents / 100;
  double? get compareAtPrice     => compareAtPriceCents != null ? compareAtPriceCents! / 100 : null;
  bool    get inStock            => inventoryCount == null || inventoryCount! > 0;
  String  get formattedPrice     => _fmt.format(price);
  String? get thumbnailUrl       => images.isNotEmpty ? images.first : null;
  String? get formattedCompareAt =>
      compareAtPrice != null ? _fmt.format(compareAtPrice!) : null;

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id:                  json['id'] as String,
        categoryId:          json['category_id'] as String?,
        name:                json['name'] as String,
        description:         json['description'] as String?,
        priceCents:          json['price_cents'] as int,
        compareAtPriceCents: json['compare_at_price_cents'] as int?,
        images:              (json['images'] as List? ?? []).cast<String>(),
        inventoryCount:      json['inventory_count'] as int?,
        isActive:            json['is_active'] as bool? ?? true,
        displayOrder:        json['display_order'] as int? ?? 0,
        tags:                (json['tags'] as List? ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'category_id':            categoryId,
        'name':                   name,
        'description':            description,
        'price_cents':            priceCents,
        'compare_at_price_cents': compareAtPriceCents,
        'images':                 images,
        'inventory_count':        inventoryCount,
        'is_active':              isActive,
        'display_order':          displayOrder,
        'tags':                   tags,
      };
}
