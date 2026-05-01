import 'package:get/get.dart';
import 'menu_item_model.dart';
import 'menu_repository.dart';

class MenuCatalogController extends GetxController {
  final MenuRepository _repo = Get.find<MenuRepository>();

  final items            = <MenuItemModel>[].obs;
  final selectedCategory = 'All'.obs;
  final isLoading        = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadItems();
  }

  Future<void> loadItems() async {
    isLoading.value = true;
    try {
      items.value = await _repo.getMenuItems();
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get categories => [
        'All',
        ...{for (final i in items) i.category},
      ];

  List<MenuItemModel> get filteredItems {
    final cat = selectedCategory.value;
    return cat == 'All' ? items : items.where((i) => i.category == cat).toList();
  }

  Future<void> createItem(Map<String, dynamic> data) async {
    await _repo.createItem(data);
    await loadItems();
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await _repo.updateItem(id, data);
    await loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _repo.deleteItem(id);
    await loadItems();
  }
}
