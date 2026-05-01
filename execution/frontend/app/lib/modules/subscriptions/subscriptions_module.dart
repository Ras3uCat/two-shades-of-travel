import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'views/subscriptions_view.dart';

class SubscriptionsModule implements AppModule {
  @override
  String get moduleId => 'subscriptions';

  @override
  NavItem? get navItem => const NavItem(
    label: 'Memberships',
    route: ERoutes.subscriptions,
    icon:  Icons.card_membership_outlined,
  );

  @override
  List<GetPage> get routes => [
    GetPage(
      name:       ERoutes.subscriptions,
      page:       () => const SubscriptionsView(),
      transition: Transition.fadeIn,
    ),
  ];

  @override
  Bindings? get binding => null;
}
