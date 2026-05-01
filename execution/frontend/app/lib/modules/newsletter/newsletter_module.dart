import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/router/app_router.dart';
import '../../modules/_registry/module_registry.dart';
import 'bindings/newsletter_binding.dart';
import 'views/newsletter_view.dart';

class NewsletterModule implements AppModule {
  @override
  String get moduleId => 'newsletter';

  @override
  NavItem? get navItem => const NavItem(
        label: 'Newsletter',
        icon: Icons.mail_outline,
        route: ERoutes.newsletter,
      );

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.newsletter,
          page: () => const NewsletterView(),
          binding: NewsletterBinding(),
          transition: Transition.fadeIn,
        ),
      ];

  @override
  Bindings? get binding => null; // per-route binding used above
}
