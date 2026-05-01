import 'package:get/get.dart';
import '../controllers/shop_admin_controller.dart';
import '../repositories/shop_repository.dart';
import '../repositories/supabase_shop_repository.dart';

class ShopAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopRepository>(() => SupabaseShopRepository());
    Get.lazyPut<ShopAdminController>(() => ShopAdminController(Get.find()));
  }
}
