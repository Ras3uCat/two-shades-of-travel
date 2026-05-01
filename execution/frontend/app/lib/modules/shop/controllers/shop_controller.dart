import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../repositories/shop_repository.dart';

class ShopController extends GetxController {
  ShopController(this._repo);
  final ShopRepository _repo;

  final products         = <ProductModel>[].obs;
  final categories       = <Map<String, dynamic>>[].obs;
  final cart             = <String, CartItemModel>{}.obs;
  final selectedCategory = RxnString();
  final discountCode     = ''.obs;
  final discountPct      = 0.obs;
  final isLoading        = false.obs;
  final isCheckingOut    = false.obs;

  static final _fmt = NumberFormat.simpleCurrency(decimalDigits: 2);

  @override
  void onInit() {
    super.onInit();
    _loadAll();
    ever(selectedCategory, (_) => _loadProducts());
  }

  Future<void> _loadAll() async {
    isLoading.value = true;
    await Future.wait([_loadCategories(), _loadProducts()]);
    isLoading.value = false;
  }

  Future<void> _loadCategories() async {
    try { categories.value = await _repo.getCategories(); } catch (_) {}
  }

  Future<void> _loadProducts() async {
    try {
      products.value = await _repo.getActiveProducts(
          categoryId: selectedCategory.value);
    } catch (_) {}
  }

  void setCategory(String? id) => selectedCategory.value = id;

  // ── Cart ──────────────────────────────────────────────────────────────────────

  void addToCart(ProductModel product, {int qty = 1}) {
    if (!product.inStock) return;
    final existing = cart[product.id];
    if (existing != null) {
      existing.quantity += qty;
      cart.refresh();
    } else {
      cart[product.id] = CartItemModel(product: product, quantity: qty);
    }
  }

  void removeFromCart(String productId) => cart.remove(productId);

  void setQuantity(String productId, int qty) {
    if (qty <= 0) {
      cart.remove(productId);
    } else {
      cart[productId]?.quantity = qty;
      cart.refresh();
    }
  }

  void clearCart() {
    cart.clear();
    discountCode.value = '';
    discountPct.value  = 0;
  }

  List<CartItemModel> get cartItems  => cart.values.toList();
  int  get cartCount                 => cart.values.fold(0, (s, i) => s + i.quantity);
  int  get subtotalCents             => cart.values.fold(0, (s, i) => s + i.subtotalCents);
  int  get discountCents             => (subtotalCents * discountPct.value / 100).round();
  int  get totalCents                => subtotalCents - discountCents;
  String get formattedSubtotal       => _fmt.format(subtotalCents / 100);
  String get formattedDiscount       => _fmt.format(discountCents / 100);
  String get formattedTotal          => _fmt.format(totalCents / 100);

  // ── Discount ──────────────────────────────────────────────────────────────────

  Future<bool> applyDiscountCode(String code) async {
    try {
      final pct = await _repo.validateDiscountCode(code.trim().toUpperCase());
      if (pct > 0) {
        discountPct.value  = pct;
        discountCode.value = code.trim().toUpperCase();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void removeDiscount() {
    discountCode.value = '';
    discountPct.value  = 0;
  }

  // ── Checkout ──────────────────────────────────────────────────────────────────

  Future<void> checkout(String clientEmail, String clientName) async {
    if (cart.isEmpty) return;
    isCheckingOut.value = true;
    try {
      final items = cart.values
          .map((i) => {'product_id': i.product.id, 'quantity': i.quantity})
          .toList();
      final url = await _repo.checkout(
        items:        items,
        clientEmail:  clientEmail,
        clientName:   clientName,
        discountCode: discountCode.value.isNotEmpty ? discountCode.value : null,
      );
      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
      } else {
        Get.snackbar('Error', 'Could not start checkout. Please try again.',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {
      Get.snackbar('Error', 'Checkout failed. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isCheckingOut.value = false;
    }
  }
}
