import 'package:get/get.dart';
import '../controllers/shop_controller.dart';
import '../repositories/shop_repository.dart';
import '../repositories/supabase_shop_repository.dart';

class ShopBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ShopRepository>(() => SupabaseShopRepository());
    Get.lazyPut<ShopController>(() => ShopController(Get.find()));
  }
}
