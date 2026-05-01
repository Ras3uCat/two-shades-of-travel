import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'bindings/events_binding.dart';
import 'views/events_list_view.dart';
import 'views/event_detail_view.dart';
import 'views/event_confirmation_view.dart';

class EventsModule implements AppModule {
  @override
  String get moduleId => 'events';

  @override
  NavItem? get navItem => NavItem(
        label: 'Events',
        icon: Icons.event_outlined,
        route: ERoutes.events,
      );

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.events,
          page: () => const EventsListView(),
          binding: EventsBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.eventsDetail,
          page: () => const EventDetailView(),
          binding: EventsBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.eventsConfirmation,
          page: () => const EventConfirmationView(),
          transition: Transition.fadeIn,
        ),
      ];

  @override
  Bindings? get binding => null;
}
