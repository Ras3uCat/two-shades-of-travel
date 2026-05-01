import 'package:get/get.dart';
import '../../../shared/services/supabase_service.dart';
import '../models/blog_post_model.dart';

/// Loads a single published post by slug (from Get.parameters['slug']).
class BlogPostController extends GetxController {
  final post      = Rxn<BlogPostModel>();
  final isLoading = false.obs;
  final notFound  = false.obs;

  @override
  void onInit() {
    super.onInit();
    final slug = Get.parameters['slug'] ?? '';
    if (slug.isNotEmpty) _load(slug);
  }

  Future<void> _load(String slug) async {
    isLoading.value = true;
    notFound.value  = false;
    try {
      final row = await SupabaseService.client
          .from('blog_posts')
          .select()
          .eq('slug', slug)
          .eq('is_published', true)
          .single();
      post.value = BlogPostModel.fromMap(row);
    } catch (_) {
      notFound.value = true;
    } finally {
      isLoading.value = false;
    }
  }
}
