part of 'app_shell.dart';

// ─── Nav Bar Widget ──────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  const _NavBar({this.elevation = 0});
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final navItems = ModuleRegistry.navItems;
    final auth = Get.find<AuthController>();

    return Material(
      color: Colors.transparent,
      elevation: elevation,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ESpacing.pagePaddingHDesktop,
          vertical: ESpacing.md,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Get.offAllNamed(ERoutes.home),
              child: Text(AppEnv.clientName, style: ETextStyles.h3),
            ),
            const Spacer(),
            ...navItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: ESpacing.lg),
                child: TextButton(
                  onPressed: () => Get.toNamed(item.route),
                  child: Text(item.label, style: ETextStyles.navItem),
                ),
              ),
            ),
            const SizedBox(width: ESpacing.lg),
            Obx(
              () =>
                  auth.isSignedIn
                      ? TextButton(onPressed: auth.signOut, child: const Text('Sign Out'))
                      : TextButton(
                        onPressed: () => Get.toNamed(ERoutes.login),
                        child: const Text('Login'),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav Drawer ──────────────────────────────────────────────────────────────
class _NavDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final navItems = ModuleRegistry.navItems;
    final auth = Get.find<AuthController>();

    return Drawer(
      backgroundColor: EColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(ESpacing.lg),
              child: Text(AppEnv.clientName, style: ETextStyles.h3),
            ),
            const Divider(),
            ...navItems.map(
              (item) => ListTile(
                leading: Icon(item.icon, color: EColors.onSurface),
                title: Text(item.label, style: ETextStyles.navItem),
                onTap: () {
                  Get.back();
                  Get.toNamed(item.route);
                },
              ),
            ),
            const Spacer(),
            Obx(
              () => ListTile(
                leading: Icon(
                  auth.isSignedIn ? Icons.logout : Icons.login,
                  color: EColors.onSurface,
                ),
                title: Text(
                  auth.isSignedIn ? 'Sign Out' : 'Team Login',
                  style: ETextStyles.navItem,
                ),
                onTap: () {
                  Get.back();
                  auth.isSignedIn ? auth.signOut() : Get.toNamed(ERoutes.login);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
