import 'package:get/get.dart';
import 'location_model.dart';
import 'location_repository.dart';

class LocationController extends GetxController {
  final LocationRepository _repository = Get.find<LocationRepository>();

  final locations = <LocationModel>[].obs;
  final isLoading = false.obs;
  final error     = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadLocations();
  }

  Future<void> loadLocations({bool activeOnly = false}) async {
    isLoading.value = true;
    error.value = null;
    try {
      locations.value = await _repository.getLocations(activeOnly: activeOnly);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createLocation({
    required String name,
    String? address,
    String? city,
    String? phone,
    String timezone = 'UTC',
    int sortOrder = 0,
  }) async {
    await _repository.createLocation(
      name: name,
      address: address,
      city: city,
      phone: phone,
      timezone: timezone,
      sortOrder: sortOrder,
    );
    await loadLocations();
  }

  Future<void> updateLocation(String id, Map<String, dynamic> data) async {
    await _repository.updateLocation(id, data);
    await loadLocations();
  }

  Future<void> deleteLocation(String id) async {
    await _repository.deleteLocation(id);
    await loadLocations();
  }
}
