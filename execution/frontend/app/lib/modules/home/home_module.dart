import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'bindings/home_binding.dart';
import 'views/home_view.dart';

class HomeModule implements AppModule {
  @override
  String get moduleId => 'home';

  @override
  NavItem? get navItem => const NavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        route: ERoutes.home,
      );

  @override
  Bindings? get binding => HomeBinding();

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.home,
          page: () => const HomeView(),
          binding: HomeBinding(),
        ),
      ];
}
