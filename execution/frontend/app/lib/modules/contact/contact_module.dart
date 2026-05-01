import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'bindings/contact_binding.dart';
import 'views/contact_view.dart';

class ContactModule implements AppModule {
  @override
  String get moduleId => 'contact';

  @override
  NavItem? get navItem => const NavItem(
        label: 'Contact',
        icon: Icons.mail_outline,
        route: ERoutes.contact,
      );

  @override
  Bindings? get binding => ContactBinding();

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.contact,
          page: () => const ContactView(),
          binding: ContactBinding(),
        ),
      ];
}
