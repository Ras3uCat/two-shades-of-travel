import 'package:get/get.dart';
import '../../modules/_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'bindings/admin_binding.dart';
import 'views/master/booking_overview_view.dart';
import 'views/master/clients_view.dart';
import 'views/master/business_config_view.dart';
import 'views/master/compliance_view.dart';
import 'views/master/service_manager_view.dart';
import 'views/master/blog_manager_view.dart';
import 'views/master/faq_manager_view.dart';
import 'views/master/gallery_manager_view.dart';
import 'views/master/staff_manager_view.dart';
import 'views/master/testimonials_manager_view.dart';
import 'views/master/gift_vouchers_view.dart';
import 'views/master/intake_questions_view.dart';
import 'views/master/packages_view.dart';
import 'views/master/waitlist_view.dart';
import 'views/master/reviews_view.dart';
import 'views/master/client_photos_view.dart';
import 'views/master/subscription_plans_view.dart';
import 'views/master/subscription_members_view.dart';
import 'views/master/referrals_view.dart' as admin_referrals;
import 'views/master/analytics_view.dart';
import 'views/master/shop_products_view.dart';
import 'views/master/shop_orders_view.dart';
import '../../modules/shop/bindings/shop_admin_binding.dart';
import '../../modules/events/bindings/events_admin_binding.dart';
import '../../modules/events/views/admin/admin_events_list_view.dart';
import '../../modules/events/views/admin/admin_event_attendees_view.dart';
import 'views/staff/staff_bookings_view.dart';
import 'views/staff/staff_bundles_view.dart';
import '../../modules/menu/menu_binding.dart';
import '../../modules/menu/menu_manager_view.dart';
import '../../modules/location/location_binding.dart';
import '../../modules/admin/views/master/location_manager_view.dart';
import 'views/staff/staff_hours_view.dart';
import 'views/staff/staff_promo_codes_view.dart';
import 'views/staff/staff_services_view.dart';
import 'views/staff/staff_time_off_view.dart';

class AdminModule implements AppModule {
  @override
  String get moduleId => 'admin';

  @override
  NavItem? get navItem => null; // admin routes are role-gated, not in public nav

  @override
  List<GetPage> get routes => [
        // ── Master routes ──────────────────────────────────────────────────
        GetPage(
          name: ERoutes.admin,
          page: () => const BookingOverviewView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminClients,
          page: () => const ClientsView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminServices,
          page: () => const ServiceManagerView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminStaff,
          page: () => const StaffManagerView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminBlog,
          page: () => const BlogManagerView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminGallery,
          page: () => const GalleryManagerView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminTestimonials,
          page: () => const TestimonialsManagerView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminFaq,
          page: () => const FaqManagerView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminConfig,
          page: () => const BusinessConfigView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminGiftVouchers,
          page: () => const GiftVouchersView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminIntake,
          page: () => const IntakeQuestionsView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminWaitlist,
          page: () => const WaitlistView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminPackages,
          page: () => const PackagesView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminReviews,
          page: () => const ReviewsView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminClientPhotos,
          page: () => const ClientPhotosView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminSubscriptionPlans,
          page: () => const SubscriptionPlansView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminSubscriptionMembers,
          page: () => const SubscriptionMembersView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminReferrals,
          page: () => const admin_referrals.ReferralsView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminAnalytics,
          page: () => const AnalyticsView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminShopProducts,
          page: () => const ShopProductsView(),
          binding: ShopAdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminShopOrders,
          page: () => const ShopOrdersView(),
          binding: ShopAdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminEvents,
          page: () => const AdminEventsListView(),
          binding: EventsAdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminEventsAttendees,
          page: () => const AdminEventAttendeesView(),
          binding: EventsAdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminCompliance,
          page: () => const ComplianceView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminMenu,
          page: () => const MenuManagerView(),
          binding: MenuBinding(),
          transition: Transition.fadeIn,
        ),
        // ── Staff routes ───────────────────────────────────────────────────
        GetPage(
          name: ERoutes.staff,
          page: () => const StaffBookingsView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.staffTimeOff,
          page: () => const StaffTimeOffView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.staffPromoCodes,
          page: () => const StaffPromoCodesView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.staffServices,
          page: () => const StaffServicesView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.staffHours,
          page: () => const StaffHoursView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.staffBundles,
          page: () => const StaffBundlesView(),
          binding: AdminBinding(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: ERoutes.adminLocations,
          page: () => const LocationManagerView(),
          binding: LocationBinding(),
          transition: Transition.fadeIn,
        ),
      ];

  @override
  Bindings? get binding => null;
}
