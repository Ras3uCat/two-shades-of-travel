import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'bindings/blog_list_binding.dart';
import 'bindings/blog_post_binding.dart';
import 'views/blog_list_view.dart';
import 'views/blog_post_view.dart';

class BlogModule implements AppModule {
  @override
  String get moduleId => 'blog';

  @override
  NavItem get navItem => const NavItem(
        label: 'Blog',
        icon: Icons.article_outlined,
        route: ERoutes.blog,
      );

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.blog,
          page: () => const BlogListView(),
          binding: BlogListBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.blogPost,
          page: () => const BlogPostView(),
          binding: BlogPostBinding(),
          transition: Transition.fadeIn,
        ),
      ];

  @override
  Bindings? get binding => null;
}
