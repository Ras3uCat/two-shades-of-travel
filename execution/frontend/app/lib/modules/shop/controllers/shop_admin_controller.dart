import 'package:get/get.dart';
import '../models/product_model.dart';
import '../models/shop_order_model.dart';
import '../repositories/shop_repository.dart';

class ShopAdminController extends GetxController {
  ShopAdminController(this._repo);
  final ShopRepository _repo;

  final products      = <ProductModel>[].obs;
  final orders        = <ShopOrderModel>[].obs;
  final discountCodes = <Map<String, dynamic>>[].obs;
  final categories    = <Map<String, dynamic>>[].obs;
  final statusFilter  = RxnString();
  final isLoading     = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
    ever(statusFilter, (_) => loadOrders());
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    await Future.wait([loadProducts(), loadOrders(), loadDiscountCodes(), loadCategories()]);
    isLoading.value = false;
  }

  Future<void> loadProducts() async {
    try { products.value = await _repo.getAllProducts(); } catch (_) {}
  }

  Future<void> loadOrders() async {
    try { orders.value = await _repo.getAllOrders(status: statusFilter.value); } catch (_) {}
  }

  Future<void> loadDiscountCodes() async {
    try { discountCodes.value = await _repo.getAllDiscountCodes(); } catch (_) {}
  }

  Future<void> loadCategories() async {
    try { categories.value = await _repo.getCategories(); } catch (_) {}
  }

  // ── Products ──────────────────────────────────────────────────────────────────

  Future<void> createProduct(Map<String, dynamic> data) async {
    await _repo.createProduct(data);
    await loadProducts();
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _repo.updateProduct(id, data);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await _repo.deleteProduct(id);
    products.removeWhere((p) => p.id == id);
  }

  // ── Orders ────────────────────────────────────────────────────────────────────

  Future<void> updateOrderStatus(String id, String status) async {
    await _repo.updateOrderStatus(id, status);
    await loadOrders();
  }

  // ── Categories ────────────────────────────────────────────────────────────────

  Future<void> createCategory(String name) async {
    await _repo.createCategory(name);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _repo.deleteCategory(id);
    await loadCategories();
  }

  // ── Discount codes ────────────────────────────────────────────────────────────

  Future<void> createDiscountCode(Map<String, dynamic> data) async {
    await _repo.createDiscountCode(data);
    await loadDiscountCodes();
  }

  Future<void> toggleDiscountCode(String id, bool active) async {
    await _repo.toggleDiscountCode(id, active);
    await loadDiscountCodes();
  }
}
