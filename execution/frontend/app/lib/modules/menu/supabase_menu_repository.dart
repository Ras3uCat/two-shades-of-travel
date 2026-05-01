import '../../shared/services/supabase_service.dart';
import 'menu_item_model.dart';
import 'menu_repository.dart';

class SupabaseMenuRepository implements MenuRepository {
  @override
  Future<List<MenuItemModel>> getMenuItems() async {
    final data = await SupabaseService.client
        .from('menu_items')
        .select()
        .order('category')
        .order('sort_order');
    return (data as List)
        .map((e) => MenuItemModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createItem(Map<String, dynamic> data) async {
    await SupabaseService.client.from('menu_items').insert(data);
  }

  @override
  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await SupabaseService.client.from('menu_items').update(data).eq('id', id);
  }

  @override
  Future<void> deleteItem(String id) async {
    await SupabaseService.client.from('menu_items').delete().eq('id', id);
  }
}
