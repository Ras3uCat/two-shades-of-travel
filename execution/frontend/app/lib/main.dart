import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_strategy/url_strategy.dart';

import 'core/bindings/initial_binding.dart';
import 'core/config/app_env.dart';
import 'core/router/app_router.dart';
import 'core/theme/e_colors.dart';
import 'core/theme/e_text_styles.dart';
import 'core/theme/theme_factory.dart';
import 'core/utils/e_platform.dart';
import 'modules/_registry/module_registry.dart';
import 'modules/admin/admin_module.dart';
import 'modules/auth/auth_module.dart';
import 'modules/blog/blog_module.dart';
import 'modules/booking/booking_module.dart';
import 'modules/contact/contact_module.dart';
import 'modules/faq/faq_module.dart';
import 'modules/gallery/gallery_module.dart';
import 'modules/chatbot/chatbot_bubble.dart';
import 'modules/gdpr/controllers/gdpr_controller.dart';
import 'modules/gdpr/widgets/gdpr_banner.dart';
import 'modules/gift/gift_module.dart';
import 'modules/home/home_module.dart';
import 'modules/intake/intake_module.dart';
import 'modules/newsletter/newsletter_module.dart';
import 'modules/referrals/referrals_module.dart';
import 'modules/services/services_module.dart';
import 'modules/menu/menu_module.dart';
import 'modules/shop/shop_module.dart';
import 'modules/events/events_module.dart';
import 'modules/subscriptions/subscriptions_module.dart';
import 'modules/testimonials/testimonials_module.dart';
import 'modules/courses/courses_module.dart';
import 'shared/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Surfaces Flutter errors in release mode rather than silently swallowing them.
  // Replace debugPrint with your crash reporter (Sentry, Firebase, etc.) when ready.
  FlutterError.onError = (details) => FlutterError.presentError(details);
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true; // handled — suppresses OS crash dialog
  };

  // Path-based routing (no hash) — required for SEO. No-op on native.
  if (kIsWeb) setPathUrlStrategy();

  // Match status bar icon brightness to app surface color on native.
  if (!kIsWeb) {
    final isDark = EColors.surface.computeLuminance() <= 0.5;
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );
  }

  // Initialize Supabase with client credentials from dart-define
  await SupabaseService.initialize();

  // GDPR controller registered early so banner can find it via GetView
  if (AppEnv.gdprEnabled) Get.put(GdprController(), permanent: true);

  // Register all available modules — registry filters to enabled ones from AppEnv
  ModuleRegistry.init([
    AdminModule(), // always-on system module (auth-gated via role routing)
    AuthModule(),
    HomeModule(),
    ContactModule(),
    BookingModule(),
    NewsletterModule(),
    TestimonialsModule(),
    FaqModule(),
    GalleryModule(),
    BlogModule(),
    if (AppEnv.giftEnabled) GiftModule(),
    if (AppEnv.intakeEnabled) IntakeModule(),
    SubscriptionsModule(),
    ReferralsModule(),
    ServicesModule(),
    if (AppEnv.moduleEnabled('menu')) MenuModule(),
    if (AppEnv.moduleEnabled('shop')) ShopModule(),
    if (AppEnv.moduleEnabled('events')) EventsModule(),
    if (AppEnv.coursesEnabled || AppEnv.moduleEnabled('courses'))
      CoursesModule(),
  ]);

  runApp(const RaspucatApp());

  // Deep link handling for native — routes Stripe redirects and universal links.
  if (!kIsWeb) {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen(_handleDeepLink);
    final initial = await appLinks.getInitialLink();
    if (initial != null) _handleDeepLink(initial);
  }
}

/// Routes incoming deep links to public-facing destinations only.
/// Admin, staff, and auth routes are excluded — they must not be reachable
/// via externally crafted URLs.
void _handleDeepLink(Uri uri) {
  const allowed = {
    '/',
    '/booking',
    '/blog',
    '/gallery',
    '/testimonials',
    '/faq',
    '/newsletter',
    '/contact',
    '/shop',
    '/referrals',
    '/subscriptions',
    '/events',
    '/services',
    '/courses',
  };
  final path = uri.path.isEmpty ? '/' : uri.path;
  final safe = allowed.any((p) => path == p || path.startsWith('$p/'));
  if (safe) Get.toNamed(path, parameters: uri.queryParameters);
}

class RaspucatApp extends StatelessWidget {
  const RaspucatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppEnv.clientName,
      theme: ThemeFactory.fromEnv(),
      initialBinding: InitialBinding(),
      initialRoute: ERoutes.home,
      getPages: AppRouter.buildRoutes(),
      unknownRoute: GetPage(
        name: ERoutes.notFound,
        page: () => const _NotFoundView(),
      ),
      // Native uses OS-native page transition; web uses fade.
      defaultTransition: EPlatform.isNative
          ? Transition.native
          : Transition.fadeIn,
      // Clamps to 240ms on native (>260ms feels sluggish on mobile).
      transitionDuration: EPlatform.nativeAnim(
        const Duration(milliseconds: 300),
      ),
      // SelectionArea makes all Text selectable on web. GDPR + chatbot composited on both.
      builder: (_, child) {
        Widget content = child!;
        if (AppEnv.gdprEnabled)    content = Stack(children: [content, const GdprBanner()]);
        if (AppEnv.chatbotEnabled) content = Stack(children: [content, const ChatbotBubble()]);
        return kIsWeb ? SelectionArea(child: content) : content;
      },
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '404',
              style: ETextStyles.displayXL.copyWith(
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 16),
            Text('Page not found', style: ETextStyles.body),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Get.offAllNamed(ERoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
