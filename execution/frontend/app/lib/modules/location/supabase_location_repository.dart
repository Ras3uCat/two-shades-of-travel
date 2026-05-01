import '../../shared/services/supabase_service.dart';
import 'location_model.dart';
import 'location_repository.dart';

class SupabaseLocationRepository implements LocationRepository {
  final _db = SupabaseService.client;

  @override
  Future<List<LocationModel>> getLocations({bool activeOnly = false}) async {
    var query = _db.from('locations').select();
    if (activeOnly) query = query.eq('is_active', true);
    final rows = await query.order('sort_order');
    return (rows as List)
        .map((r) => LocationModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LocationModel> createLocation({
    required String name,
    String? address,
    String? city,
    String? phone,
    String timezone = 'UTC',
    int sortOrder = 0,
  }) async {
    final row = await _db.from('locations').insert({
      'name': name,
      'timezone': timezone,
      'sort_order': sortOrder,
      if (address != null && address.isNotEmpty) 'address': address,
      if (city != null && city.isNotEmpty) 'city': city,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    }).select().single();
    return LocationModel.fromMap(row);
  }

  @override
  Future<void> updateLocation(String id, Map<String, dynamic> data) async {
    await _db.from('locations').update(data).eq('id', id);
  }

  @override
  Future<void> deleteLocation(String id) async {
    await _db.from('locations').delete().eq('id', id);
  }
}
