import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/app_env.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../../modules/auth/controllers/auth_controller.dart';

/// AdminShell — outer chrome for both master and staff portals.
/// Renders a sidebar on desktop, drawer on mobile.
/// [isMaster] drives which nav items are shown.
class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.isMaster,
  });

  final Widget child;
  final String currentRoute;
  final bool isMaster;

  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < ESpacing.mobileBreak;

    if (isMobile) {
      return Scaffold(
        backgroundColor: EColors.surface,
        appBar: _AdminAppBar(isMaster: isMaster),
        drawer: _AdminDrawer(
            currentRoute: currentRoute, isMaster: isMaster),
        body: child,
      );
    }

    return Scaffold(
      backgroundColor: EColors.surface,
      body: Row(children: [
        _AdminSidebar(currentRoute: currentRoute, isMaster: isMaster),
        const VerticalDivider(width: 1, thickness: 0.5),
        Expanded(child: child),
      ]),
    );
  }
}

// ── Nav items ─────────────────────────────────────────────────────────────────
List<_NavEntry> get _masterNav => [
  const _NavEntry('Bookings',      Icons.calendar_today_outlined,  ERoutes.admin),
  const _NavEntry('Analytics',     Icons.bar_chart_outlined,       ERoutes.adminAnalytics),
  if (AppEnv.moduleEnabled('crm'))
    const _NavEntry('Clients',     Icons.people_outline,           ERoutes.adminClients),
  const _NavEntry('Services',      Icons.spa_outlined,             ERoutes.adminServices),
  const _NavEntry('Team',          Icons.group_outlined,           ERoutes.adminStaff),
  const _NavEntry('Gallery',       Icons.photo_library_outlined,   ERoutes.adminGallery),
  const _NavEntry('Blog',          Icons.article_outlined,         ERoutes.adminBlog),
  const _NavEntry('Testimonials',  Icons.format_quote_outlined,    ERoutes.adminTestimonials),
  const _NavEntry('FAQ',           Icons.quiz_outlined,            ERoutes.adminFaq),
  if (AppEnv.giftEnabled)
    const _NavEntry('Gift Vouchers', Icons.card_giftcard_outlined, ERoutes.adminGiftVouchers),
  if (AppEnv.intakeEnabled)
    const _NavEntry('Intake Forms',  Icons.assignment_outlined,    ERoutes.adminIntake),
  if (AppEnv.waitlistEnabled)
    const _NavEntry('Waitlist',      Icons.people_outline,         ERoutes.adminWaitlist),
  if (AppEnv.packagesEnabled)
    const _NavEntry('Packages',      Icons.local_offer_outlined,   ERoutes.adminPackages),
  if (AppEnv.reviewsEnabled)
    const _NavEntry('Reviews',       Icons.rate_review_outlined,   ERoutes.adminReviews),
  if (AppEnv.clientPhotosEnabled)
    const _NavEntry('Client Photos', Icons.photo_camera_outlined,  ERoutes.adminClientPhotos),
  if (AppEnv.coursesEnabled)
    const _NavEntry('Courses', Icons.play_circle_outline, ERoutes.adminCourses),
  const _NavEntry('Settings',      Icons.settings_outlined,        ERoutes.adminConfig),
  const _NavEntry('Compliance',    Icons.shield_outlined,          ERoutes.adminCompliance),
  if (AppEnv.moduleEnabled('subscriptions')) ...[
    _NavEntry('Subscription Plans',  Icons.card_membership_outlined, ERoutes.adminSubscriptionPlans),
    _NavEntry('Subscribers',         Icons.people_outline,           ERoutes.adminSubscriptionMembers),
  ],
  if (AppEnv.moduleEnabled('referrals'))
    _NavEntry('Referrals', Icons.share_outlined, ERoutes.adminReferrals),
  if (AppEnv.moduleEnabled('shop')) ...[
    _NavEntry('Products',   Icons.inventory_2_outlined,  ERoutes.adminShopProducts),
    _NavEntry('Orders',     Icons.shopping_bag_outlined, ERoutes.adminShopOrders),
  ],
  if (AppEnv.moduleEnabled('events'))
    _NavEntry('Events', Icons.event_outlined, ERoutes.adminEvents),
  if (AppEnv.moduleEnabled('menu'))
    _NavEntry('Menu', Icons.menu_book_outlined, ERoutes.adminMenu),
  if (AppEnv.locationsEnabled)
    _NavEntry('Locations', Icons.location_on_outlined, ERoutes.adminLocations),
];

List<_NavEntry> get _staffNav => [
  const _NavEntry('My Bookings',  Icons.calendar_today_outlined,  ERoutes.staff),
  const _NavEntry('Time Off',     Icons.event_busy_outlined,      ERoutes.staffTimeOff),
  const _NavEntry('Promo Codes',  Icons.local_offer_outlined,     ERoutes.staffPromoCodes),
  const _NavEntry('My Services',  Icons.spa_outlined,             ERoutes.staffServices),
  const _NavEntry('My Hours',     Icons.schedule_outlined,        ERoutes.staffHours),
  const _NavEntry('My Bundles',   Icons.local_offer_outlined,     ERoutes.staffBundles),
];

class _NavEntry {
  const _NavEntry(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}

// ── Sidebar (desktop) ─────────────────────────────────────────────────────────
class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.currentRoute, required this.isMaster});
  final String currentRoute;
  final bool isMaster;

  @override
  Widget build(BuildContext context) {
    final nav = isMaster ? _masterNav : _staffNav;
    return Container(
      width: 200,
      color: EColors.surfaceVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(ESpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMaster ? 'MASTER' : 'STAFF',
                  style: ETextStyles.overline,
                ),
                const SizedBox(height: ESpacing.xs),
                Text('Dashboard', style: ETextStyles.h3),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),
          ...nav.map((e) => _SidebarItem(
                entry: e,
                isActive: currentRoute == e.route,
              )),
          const Spacer(),
          const Divider(height: 1, thickness: 0.5),
          _SignOutTile(),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.entry, required this.isActive});
  final _NavEntry entry;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.offAllNamed(entry.route),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: ESpacing.lg, vertical: ESpacing.md),
        color: isActive ? EColors.primaryLight : Colors.transparent,
        child: Row(children: [
          Icon(entry.icon,
              size: 18,
              color: isActive ? EColors.primary : EColors.onSurfaceMuted),
          const SizedBox(width: ESpacing.sm),
          Text(
            entry.label,
            style: ETextStyles.navItem.copyWith(
              color: isActive ? EColors.primary : EColors.onSurface,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ]),
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.find<AuthController>().signOut(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: ESpacing.lg, vertical: ESpacing.md),
        child: Row(children: [
          Icon(Icons.logout, size: 18, color: EColors.onSurfaceMuted),
          const SizedBox(width: ESpacing.sm),
          Text('Sign Out',
              style: ETextStyles.navItem.copyWith(
                  color: EColors.onSurfaceMuted)),
        ]),
      ),
    );
  }
}

// ── AppBar (mobile) ───────────────────────────────────────────────────────────
class _AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AdminAppBar({required this.isMaster});
  final bool isMaster;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: EColors.surfaceVariant,
      title: Text(
        isMaster ? 'Master Dashboard' : 'Staff Portal',
        style: ETextStyles.h3,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: EColors.onSurfaceMuted),
          onPressed: () => Get.find<AuthController>().signOut(),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

// ── Drawer (mobile) ───────────────────────────────────────────────────────────
class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({required this.currentRoute, required this.isMaster});
  final String currentRoute;
  final bool isMaster;

  @override
  Widget build(BuildContext context) {
    final nav = isMaster ? _masterNav : _staffNav;
    return Drawer(
      backgroundColor: EColors.surfaceVariant,
      child: Column(children: [
        const SizedBox(height: ESpacing.xxl),
        ...nav.map((e) => ListTile(
              leading: Icon(e.icon,
                  color: currentRoute == e.route
                      ? EColors.primary
                      : EColors.onSurfaceMuted),
              title: Text(e.label,
                  style: ETextStyles.navItem.copyWith(
                    color: currentRoute == e.route
                        ? EColors.primary
                        : EColors.onSurface,
                  )),
              selected: currentRoute == e.route,
              onTap: () {
                Navigator.pop(context);
                Get.offAllNamed(e.route);
              },
            )),
        const Spacer(),
        ListTile(
          leading:
              Icon(Icons.logout, color: EColors.onSurfaceMuted),
          title: Text('Sign Out',
              style:
                  ETextStyles.navItem.copyWith(color: EColors.onSurfaceMuted)),
          onTap: () => Get.find<AuthController>().signOut(),
        ),
        const SizedBox(height: ESpacing.lg),
      ]),
    );
  }
}
