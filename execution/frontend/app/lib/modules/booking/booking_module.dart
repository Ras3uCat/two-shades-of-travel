import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'bindings/booking_binding.dart';
import 'views/booking_screen.dart';
import 'views/booking_confirmation_view.dart';
import 'views/review_view.dart';

class BookingModule implements AppModule {
  @override
  String get moduleId => 'booking';

  @override
  NavItem get navItem => const NavItem(
        label: 'Book',
        icon: Icons.calendar_month_outlined,
        route: ERoutes.booking,
      );

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.booking,
          page: () => const BookingScreen(),
          binding: BookingBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.confirmation,
          page: () => const BookingConfirmationView(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.review,
          page: () => const ReviewView(),
          transition: Transition.fadeIn,
        ),
      ];

  @override
  Bindings? get binding => null; // per-route bindings used above
}
