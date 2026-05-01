import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'menu_binding.dart';
import 'menu_catalog_view.dart';

class MenuModule implements AppModule {
  @override
  String get moduleId => 'menu';

  @override
  NavItem get navItem => const NavItem(
        label: 'Menu',
        icon: Icons.menu_book_outlined,
        route: ERoutes.menu,
      );

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.menu,
          page: () => const MenuCatalogView(),
          binding: MenuBinding(),
          transition: Transition.fadeIn,
        ),
      ];

  @override
  Bindings? get binding => null;
}
