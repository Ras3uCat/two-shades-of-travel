import 'package:get/get.dart';
import '../../../shared/services/supabase_service.dart';
import '../models/testimonial_model.dart';

class TestimonialsController extends GetxController {
  final testimonials = <TestimonialModel>[].obs;
  final isLoading    = false.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final rows = await SupabaseService.client
          .from('testimonials')
          .select()
          .eq('is_active', true)
          .order('display_order');
      testimonials.value = (rows as List)
          .map((r) => TestimonialModel.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      testimonials.value = [];
    } finally {
      isLoading.value = false;
    }
  }
}
