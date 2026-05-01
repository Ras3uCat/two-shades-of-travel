import 'location_model.dart';

abstract class LocationRepository {
  Future<List<LocationModel>> getLocations({bool activeOnly = false});

  Future<LocationModel> createLocation({
    required String name,
    String? address,
    String? city,
    String? phone,
    String timezone = 'UTC',
    int sortOrder = 0,
  });

  Future<void> updateLocation(String id, Map<String, dynamic> data);

  Future<void> deleteLocation(String id);
}
