import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsController extends GetxController {
  final _client = Supabase.instance.client;

  final period    = 'week'.obs;
  final isLoading = false.obs;
  final _data     = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    load();
    ever(period, (_) => load());
  }

  void setPeriod(String p) => period.value = p;

  Future<void> load() async {
    isLoading.value = true;
    try {
      final result = await _client
          .rpc('get_revenue_summary', params: {'p_period': period.value});
      _data.value = (result as Map?)?.cast<String, dynamic>();
    } catch (_) {
      _data.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> get kpis =>
      (_data.value?['kpis'] as Map?)?.cast<String, dynamic>() ?? {};

  List<Map<String, dynamic>> get revenueByPeriod =>
      ((_data.value?['revenue_by_period'] as List?) ?? [])
          .cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get topServices =>
      ((_data.value?['top_services'] as List?) ?? [])
          .cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get busiestDays =>
      ((_data.value?['busiest_days'] as List?) ?? [])
          .cast<Map<String, dynamic>>();

  // ── Shop (only populated when 086_shop_analytics.sql is deployed) ────────────
  Map<String, dynamic> get shopKpis =>
      (_data.value?['shop_kpis'] as Map?)?.cast<String, dynamic>() ?? {};

  List<Map<String, dynamic>> get shopRevenueByPeriod =>
      ((_data.value?['shop_revenue_by_period'] as List?) ?? [])
          .cast<Map<String, dynamic>>();

  List<Map<String, dynamic>> get topProducts =>
      ((_data.value?['top_products'] as List?) ?? [])
          .cast<Map<String, dynamic>>();
}
