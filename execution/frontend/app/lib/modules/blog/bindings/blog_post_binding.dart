import 'package:get/get.dart';
import '../controllers/blog_post_controller.dart';

class BlogPostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BlogPostController>(() => BlogPostController());
  }
}
