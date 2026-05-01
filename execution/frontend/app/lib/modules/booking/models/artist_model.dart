/// AvailabilityWindow — a time-of-day range for a given weekday.
class AvailabilityWindow {
  final int weekday;      // 1=Mon … 7=Sun
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const AvailabilityWindow({
    required this.weekday,
    required this.startHour,
    this.startMinute = 0,
    required this.endHour,
    this.endMinute = 0,
  });

  int get startMinutes => startHour * 60 + startMinute;
  int get endMinutes   => endHour * 60 + endMinute;

  String get displayStart => _fmt(startHour, startMinute);
  String get displayEnd   => _fmt(endHour, endMinute);

  String _fmt(int h, int m) {
    final period = h < 12 ? 'AM' : 'PM';
    final hour   = h == 0 ? 12 : h > 12 ? h - 12 : h;
    final minStr = m == 0 ? '' : ':${m.toString().padLeft(2, '0')} ';
    return '$hour$minStr$period';
  }
}

class ArtistModel {
  final String id;
  final String name;
  final String specialty;
  final String bio;
  final String? photoUrl;   // Supabase Storage URL; nullable
  final String? locationId; // profiles.location_id — null = unassigned / global
  final List<String> offeredServiceIds;
  final List<AvailabilityWindow> availability;

  const ArtistModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.bio,
    this.photoUrl,
    this.locationId,
    required this.offeredServiceIds,
    this.availability = const [],
  });

  bool offersAllServices(List<String> serviceIds) =>
      serviceIds.every((id) => offeredServiceIds.contains(id));

  List<AvailabilityWindow> windowsFor(int weekday) =>
      availability.where((w) => w.weekday == weekday).toList();

  factory ArtistModel.fromMap(Map<String, dynamic> map) {
    return ArtistModel(
      id:                map['id'] as String,
      name:              map['display_name'] as String? ?? 'Artist',
      specialty:         (map['specialties'] as List?)?.first as String? ?? '',
      bio:               map['bio'] as String? ?? '',
      photoUrl:          map['photo_url'] as String?,
      locationId:        map['location_id'] as String?,
      offeredServiceIds: (map['service_ids'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  ArtistModel copyWith({
    String? id,
    String? name,
    String? specialty,
    String? bio,
    String? photoUrl,
    String? locationId,
    List<String>? offeredServiceIds,
    List<AvailabilityWindow>? availability,
  }) =>
      ArtistModel(
        id:                id ?? this.id,
        name:              name ?? this.name,
        specialty:         specialty ?? this.specialty,
        bio:               bio ?? this.bio,
        photoUrl:          photoUrl ?? this.photoUrl,
        locationId:        locationId ?? this.locationId,
        offeredServiceIds: offeredServiceIds ?? this.offeredServiceIds,
        availability:      availability ?? this.availability,
      );
}
