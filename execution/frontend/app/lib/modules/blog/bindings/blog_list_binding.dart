import 'package:get/get.dart';
import '../controllers/blog_controller.dart';

class BlogListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BlogController>(() => BlogController());
  }
}
