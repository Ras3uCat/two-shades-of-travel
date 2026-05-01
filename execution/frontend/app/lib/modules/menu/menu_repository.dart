import 'menu_item_model.dart';

abstract class MenuRepository {
  Future<List<MenuItemModel>> getMenuItems();
  Future<void> createItem(Map<String, dynamic> data);
  Future<void> updateItem(String id, Map<String, dynamic> data);
  Future<void> deleteItem(String id);
}
