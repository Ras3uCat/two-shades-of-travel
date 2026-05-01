import 'package:get/get.dart';
import '../../../shared/services/supabase_service.dart';
import '../models/faq_item_model.dart';

class FaqController extends GetxController {
  final faqs      = <FaqItemModel>[].obs;
  final isLoading = false.obs;

  /// All unique categories in display order.
  List<String> get categories {
    final seen = <String>{};
    return faqs
        .map((f) => f.category ?? '')
        .where(seen.add)
        .toList();
  }

  List<FaqItemModel> itemsForCategory(String category) =>
      faqs.where((f) => (f.category ?? '') == category).toList();

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final rows = await SupabaseService.client
          .from('faqs')
          .select()
          .eq('is_active', true)
          .order('display_order');
      faqs.value = (rows as List)
          .map((r) => FaqItemModel.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      faqs.value = [];
    } finally {
      isLoading.value = false;
    }
  }
}
