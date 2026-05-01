import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'bindings/gallery_binding.dart';
import 'views/gallery_view.dart';

class GalleryModule implements AppModule {
  @override
  String get moduleId => 'gallery';

  @override
  NavItem get navItem => const NavItem(
        label: 'Gallery',
        icon: Icons.photo_library_outlined,
        route: ERoutes.gallery,
      );

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.gallery,
          page: () => const GalleryView(),
          binding: GalleryBinding(),
          transition: Transition.fadeIn,
        ),
      ];

  @override
  Bindings? get binding => null;
}
