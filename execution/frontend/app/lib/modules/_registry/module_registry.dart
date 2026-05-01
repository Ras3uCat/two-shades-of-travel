import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/app_env.dart';

/// AppModule — contract every feature module must implement.
abstract class AppModule {
  String get moduleId;
  NavItem? get navItem;      // null = not shown in nav (e.g. auth)
  List<GetPage> get routes;
  Bindings? get binding;
}

class NavItem {
  const NavItem({required this.label, required this.icon, required this.route});
  final String label;
  final IconData icon;
  final String route;
}

/// ModuleRegistry — reads AppEnv.modules, instantiates active modules,
/// and provides routes + nav items to the router and shell.
class ModuleRegistry {
  ModuleRegistry._();

  static final List<AppModule> _active = [];
  static bool _initialized = false;

  static void init(List<AppModule> allModules) {
    if (_initialized) return;
    _active.clear();
    for (final module in allModules) {
      if (AppEnv.moduleEnabled(module.moduleId)) {
        _active.add(module);
      }
    }
    _initialized = true;
  }

  static List<AppModule> get activeModules => List.unmodifiable(_active);

  static List<GetPage> get allRoutes =>
      _active.expand((m) => m.routes).toList();

  static List<NavItem> get navItems =>
      _active.map((m) => m.navItem).whereType<NavItem>().toList();

  static bool isEnabled(String moduleId) =>
      _active.any((m) => m.moduleId == moduleId);
}
