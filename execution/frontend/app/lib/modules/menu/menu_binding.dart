import 'package:get/get.dart';
import 'menu_controller.dart';
import 'menu_repository.dart';
import 'supabase_menu_repository.dart';

class MenuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MenuRepository>(() => SupabaseMenuRepository());
    Get.lazyPut<MenuCatalogController>(() => MenuCatalogController());
  }
}
