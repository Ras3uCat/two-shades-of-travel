import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'views/referrals_view.dart';

class ReferralsModule implements AppModule {
  @override
  String get moduleId => 'referrals';

  @override
  NavItem? get navItem => const NavItem(
    label: 'Refer a Friend',
    route: ERoutes.referrals,
    icon:  Icons.share_outlined,
  );

  @override
  List<GetPage> get routes => [
    GetPage(
      name:       ERoutes.referrals,
      page:       () => const ReferralsView(),
      transition: Transition.fadeIn,
    ),
  ];

  @override
  Bindings? get binding => null;
}
