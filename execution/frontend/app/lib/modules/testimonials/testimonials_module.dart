import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/router/app_router.dart';
import '../../modules/_registry/module_registry.dart';
import 'bindings/testimonials_binding.dart';
import 'views/testimonials_view.dart';

class TestimonialsModule implements AppModule {
  @override
  String get moduleId => 'testimonials';

  @override
  NavItem? get navItem => const NavItem(
        label: 'Reviews',
        icon: Icons.format_quote_outlined,
        route: ERoutes.testimonials,
      );

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.testimonials,
          page: () => const TestimonialsView(),
          binding: TestimonialsBinding(),
          transition: Transition.fadeIn,
        ),
      ];

  @override
  Bindings? get binding => null;
}
