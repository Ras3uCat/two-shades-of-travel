import 'package:get/get.dart';
import '../../../shared/services/supabase_service.dart';
import '../models/blog_post_model.dart';

/// Loads the list of published blog posts.
class BlogController extends GetxController {
  final posts     = <BlogPostModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final rows = await SupabaseService.client
          .from('blog_posts')
          .select()
          .eq('is_published', true)
          .order('published_at', ascending: false);
      posts.value = (rows as List)
          .map((r) => BlogPostModel.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      posts.value = [];
    } finally {
      isLoading.value = false;
    }
  }
}
