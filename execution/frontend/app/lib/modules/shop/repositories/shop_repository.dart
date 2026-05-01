import '../models/product_model.dart';
import '../models/shop_order_model.dart';

abstract class ShopRepository {
  // ── Public shop ──────────────────────────────────────────────────────────────
  Future<List<ProductModel>> getActiveProducts({String? categoryId});
  Future<List<Map<String, dynamic>>> getCategories();
  Future<int> validateDiscountCode(String code);
  Future<String?> checkout({
    required List<Map<String, dynamic>> items,
    required String clientEmail,
    required String clientName,
    String? discountCode,
  });
  Future<ShopOrderModel?> getOrder(String orderId);

  // ── Admin ────────────────────────────────────────────────────────────────────
  Future<List<ProductModel>> getAllProducts();
  Future<void> createProduct(Map<String, dynamic> data);
  Future<void> updateProduct(String id, Map<String, dynamic> data);
  Future<void> deleteProduct(String id);
  Future<List<ShopOrderModel>> getAllOrders({String? status});
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> createCategory(String name);
  Future<void> deleteCategory(String id);
  Future<void> createDiscountCode(Map<String, dynamic> data);
  Future<void> toggleDiscountCode(String id, bool active);
  Future<List<Map<String, dynamic>>> getAllDiscountCodes();
}
