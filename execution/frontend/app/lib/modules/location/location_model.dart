class LocationModel {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final String? phone;
  final String timezone;
  final bool isActive;
  final int sortOrder;

  const LocationModel({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.phone,
    required this.timezone,
    required this.isActive,
    required this.sortOrder,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) => LocationModel(
        id:        map['id'] as String,
        name:      map['name'] as String,
        address:   map['address'] as String?,
        city:      map['city'] as String?,
        phone:     map['phone'] as String?,
        timezone:  map['timezone'] as String? ?? 'UTC',
        isActive:  map['is_active'] as bool? ?? true,
        sortOrder: map['sort_order'] as int? ?? 0,
      );

  String get displayAddress =>
      [address, city].where((s) => s != null && s.isNotEmpty).join(', ');
}
