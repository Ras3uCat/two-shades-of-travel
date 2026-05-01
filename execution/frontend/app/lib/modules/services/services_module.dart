import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import '../home/bindings/home_binding.dart';
import 'bindings/service_detail_binding.dart';
import 'views/services_list_view.dart';
import 'views/service_detail_view.dart';

class ServicesModule implements AppModule {
  @override
  String get moduleId => 'services';

  @override
  NavItem get navItem => const NavItem(
    label: 'Services',
    icon: Icons.spa_outlined,
    route: ERoutes.services,
  );

  @override
  List<GetPage> get routes => [
    GetPage(
      name: ERoutes.services,
      page: () => const ServicesListView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: ERoutes.serviceDetail,
      page: () => const ServiceDetailView(),
      binding: ServiceDetailBinding(),
      transition: Transition.fadeIn,
    ),
  ];

  @override
  Bindings? get binding => null;
}
