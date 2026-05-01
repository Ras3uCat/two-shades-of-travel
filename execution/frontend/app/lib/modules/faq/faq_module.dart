import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/router/app_router.dart';
import '../../modules/_registry/module_registry.dart';
import 'bindings/faq_binding.dart';
import 'views/faq_view.dart';

class FaqModule implements AppModule {
  @override
  String get moduleId => 'faq';

  @override
  NavItem? get navItem => const NavItem(
        label: 'FAQ',
        icon: Icons.quiz_outlined,
        route: ERoutes.faq,
      );

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.faq,
          page: () => const FaqView(),
          binding: FaqBinding(),
          transition: Transition.fadeIn,
        ),
      ];

  @override
  Bindings? get binding => null;
}
