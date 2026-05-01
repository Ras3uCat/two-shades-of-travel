class MenuItemModel {
  final String id;
  final String category;
  final String name;
  final String? description;
  final int? price; // cents — null means "Price on request"
  final String? imageUrl;
  final bool isAvailable;
  final int sortOrder;

  const MenuItemModel({
    required this.id,
    required this.category,
    required this.name,
    this.description,
    this.price,
    this.imageUrl,
    required this.isAvailable,
    required this.sortOrder,
  });

  String get displayPrice =>
      price == null ? 'Price on request' : '\$${(price! / 100).toStringAsFixed(2)}';

  factory MenuItemModel.fromMap(Map<String, dynamic> map) => MenuItemModel(
        id:          map['id']          as String,
        category:    map['category']    as String,
        name:        map['name']        as String,
        description: map['description'] as String?,
        price:       map['price']       as int?,
        imageUrl:    map['image_url']   as String?,
        isAvailable: map['is_available'] as bool? ?? true,
        sortOrder:   map['sort_order']   as int? ?? 0,
      );
}
