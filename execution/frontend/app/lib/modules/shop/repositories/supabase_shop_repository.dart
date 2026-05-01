import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../models/shop_order_model.dart';
import 'shop_repository.dart';

class SupabaseShopRepository implements ShopRepository {
  final _client = Supabase.instance.client;

  // ── Public shop ──────────────────────────────────────────────────────────────

  @override
  Future<List<ProductModel>> getActiveProducts({String? categoryId}) async {
    var query = _client.from('products').select().eq('is_active', true);
    if (categoryId != null) query = query.eq('category_id', categoryId);
    final rows = await query.order('display_order');
    return rows.map((r) => ProductModel.fromJson(r)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    final rows = await _client
        .from('product_categories')
        .select()
        .order('display_order');
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<int> validateDiscountCode(String code) async {
    final result = await _client
        .rpc('validate_shop_discount', params: {'p_code': code});
    return (result as int?) ?? 0;
  }

  @override
  Future<String?> checkout({
    required List<Map<String, dynamic>> items,
    required String clientEmail,
    required String clientName,
    String? discountCode,
  }) async {
    final response = await _client.functions.invoke(
      'create-shop-checkout',
      body: {
        'items':        items,
        'client_email': clientEmail,
        'client_name':  clientName,
        if (discountCode != null && discountCode.isNotEmpty)
          'discount_code': discountCode,
      },
    );
    if (response.status != 200) return null;
    return (response.data as Map?)?['url'] as String?;
  }

  @override
  Future<ShopOrderModel?> getOrder(String orderId) async {
    final row = await _client
        .from('shop_orders')
        .select('*, shop_order_items(*)')
        .eq('id', orderId)
        .single();
    return ShopOrderModel.fromJson(row);
  }

  // ── Admin ────────────────────────────────────────────────────────────────────

  @override
  Future<List<ProductModel>> getAllProducts() async {
    final rows = await _client
        .from('products')
        .select()
        .order('display_order');
    return rows.map((r) => ProductModel.fromJson(r)).toList();
  }

  @override
  Future<void> createProduct(Map<String, dynamic> data) async {
    await _client.from('products').insert(data);
  }

  @override
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _client.from('products').update(data).eq('id', id);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  @override
  Future<List<ShopOrderModel>> getAllOrders({String? status}) async {
    var query = _client
        .from('shop_orders')
        .select('*, shop_order_items(*)');
    if (status != null) query = query.eq('status', status);
    final rows = await query.order('created_at', ascending: false).limit(200);
    return rows.map((r) => ShopOrderModel.fromJson(r)).toList();
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client
        .from('shop_orders')
        .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', orderId);
  }

  @override
  Future<void> createCategory(String name) async {
    await _client.from('product_categories').insert({'name': name});
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _client.from('product_categories').delete().eq('id', id);
  }

  @override
  Future<void> createDiscountCode(Map<String, dynamic> data) async {
    await _client.from('shop_discount_codes').insert(data);
  }

  @override
  Future<void> toggleDiscountCode(String id, bool active) async {
    await _client.from('shop_discount_codes').update({'is_active': active}).eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllDiscountCodes() async {
    final rows = await _client
        .from('shop_discount_codes')
        .select()
        .order('created_at', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }
}
