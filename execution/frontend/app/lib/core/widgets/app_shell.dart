import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../config/app_env.dart';
import '../router/app_router.dart';
import '../theme/e_colors.dart';
import '../theme/e_spacing.dart';
import '../theme/e_text_styles.dart';
import '../theme/personality_theme.dart';
import '../../modules/_registry/module_registry.dart';
import '../../modules/auth/controllers/auth_controller.dart';

part '_app_shell_nav.dart';

/// AppShell — wraps every page with the nav bar (desktop) or drawer (mobile).
/// Nav style and appearance driven by PersonalityTheme + AppEnv.navStyle.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Native iOS/Android: always bottom navigation bar regardless of navStyle.
    if (!kIsWeb) return _BottomNavShell(child: child);

    // Web: responsive — small viewport gets drawer, wide viewport respects navStyle.
    final width = MediaQuery.of(context).size.width;
    if (width < ESpacing.tabletBreak) return _MobileShell(child: child);

    return switch (AppEnv.navStyle) {
      'sidebar' => _SidebarShell(child: child),
      'minimal' => _MinimalShell(child: child),
      'hamburger' => _MobileShell(child: child),
      _ => _TopBarShell(child: child),
    };
  }
}

// ─── Bottom Nav Shell (native iOS / Android) ─────────────────────────────────
class _BottomNavShell extends StatefulWidget {
  const _BottomNavShell({required this.child});
  final Widget child;

  @override
  State<_BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<_BottomNavShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Sync the selected tab from the current route so deep links and
    // Stripe redirects highlight the correct destination automatically.
    final route = Get.currentRoute;
    final items = ModuleRegistry.navItems;
    final idx = items.indexWhere((i) => route == i.route || route.startsWith('${i.route}/'));
    if (idx >= 0) _selectedIndex = idx;
  }

  @override
  Widget build(BuildContext context) {
    final navItems = ModuleRegistry.navItems;
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        elevation: 0,
        title: GestureDetector(
          onTap: () => Get.offAllNamed(ERoutes.home),
          child: Text(AppEnv.clientName, style: ETextStyles.h3),
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                auth.isSignedIn ? Icons.logout_outlined : Icons.login_outlined,
                color: EColors.onSurfaceMuted,
              ),
              tooltip: auth.isSignedIn ? 'Sign Out' : 'Login',
              onPressed: () => auth.isSignedIn ? auth.signOut() : Get.toNamed(ERoutes.login),
            ),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar:
          navItems.isEmpty
              ? null
              : NavigationBar(
                selectedIndex: _selectedIndex.clamp(0, navItems.length - 1),
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                  Get.offAllNamed(navItems[index].route);
                },
                destinations:
                    navItems
                        .map(
                          (item) => NavigationDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.icon, color: EColors.primary),
                            label: item.label,
                          ),
                        )
                        .toList(),
              ),
    );
  }
}

// ─── Top Bar (overlay / sticky) ─────────────────────────────────────────────
class _TopBarShell extends StatefulWidget {
  const _TopBarShell({required this.child});
  final Widget child;

  @override
  State<_TopBarShell> createState() => _TopBarShellState();
}

class _TopBarShellState extends State<_TopBarShell> {
  final ScrollController _scroll = ScrollController();
  double _opacity = AppEnv.navStyle == 'overlay' ? 0.0 : 1.0;

  @override
  void initState() {
    super.initState();
    if (AppEnv.navStyle == 'overlay') {
      _scroll.addListener(() {
        final newOpacity = (_scroll.offset / 120).clamp(0.0, 1.0);
        if ((newOpacity - _opacity).abs() > 0.01) {
          setState(() => _opacity = newOpacity);
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = PersonalityTheme.fromEnv();
    return Stack(
      children: [
        SingleChildScrollView(controller: _scroll, child: widget.child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: EColors.surface.withValues(alpha: _opacity),
            child: _NavBar(elevation: _opacity * pt.navElevation),
          ),
        ),
      ],
    );
  }
}

// ─── Mobile Shell (drawer on all viewports — used for hamburger + small web) ─
class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        elevation: 0,
        title: GestureDetector(
          onTap: () => Get.offAllNamed(ERoutes.home),
          child: Text(AppEnv.clientName, style: ETextStyles.h3),
        ),
      ),
      drawer: _NavDrawer(),
      body: child,
    );
  }
}

// ─── Sidebar Shell ───────────────────────────────────────────────────────────
class _SidebarShell extends StatelessWidget {
  const _SidebarShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(children: [SizedBox(width: 240, child: _NavDrawer()), Expanded(child: child)]);
  }
}

// ─── Minimal Shell ───────────────────────────────────────────────────────────
class _MinimalShell extends StatelessWidget {
  const _MinimalShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: ESpacing.lg,
          left: ESpacing.pagePaddingHDesktop,
          right: ESpacing.pagePaddingHDesktop,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Get.offAllNamed(ERoutes.home),
                child: Text(AppEnv.clientName, style: ETextStyles.h3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
