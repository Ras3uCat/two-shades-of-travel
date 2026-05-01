import 'package:get/get.dart';
import '../../modules/_registry/module_registry.dart';

/// Route name constants — add here as modules are built.
class ERoutes {
  ERoutes._();
  static const home = '/';
  static const contact = '/contact';
  static const auth = '/auth';
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const admin = '/admin';
  static const adminClients = '/admin/clients';
  static const adminServices = '/admin/services';
  static const adminTestimonials = '/admin/testimonials';
  static const adminFaq = '/admin/faq';
  static const adminConfig = '/admin/config';
  static const staff = '/staff';
  static const staffTimeOff = '/staff/time-off';
  static const staffPromoCodes = '/staff/promo-codes';
  static const staffServices = '/staff/services';
  static const staffHours = '/staff/hours';
  static const staffBundles = '/staff/bundles';
  static const booking = '/booking';
  static const confirmation = '/booking/confirmation';
  static const newsletter = '/newsletter';
  static const testimonials = '/testimonials';
  static const faq = '/faq';
  static const gallery = '/gallery';
  static const adminGallery = '/admin/gallery';
  static const adminStaff = '/admin/staff';
  static const blog = '/blog';
  static const blogPost = '/blog/:slug';
  static const adminBlog = '/admin/blog';
  static const profile = '/profile';
  static const gift = '/gift';
  static const giftSuccess = '/gift/success';
  static const intake = '/intake';
  static const adminGiftVouchers = '/admin/gift-vouchers';
  static const adminIntake = '/admin/intake';
  static const adminWaitlist = '/admin/waitlist';
  static const adminPackages = '/admin/packages';
  static const review = '/review';
  static const adminReviews = '/admin/reviews';
  static const adminClientPhotos = '/admin/client-photos';
  static const subscriptions = '/subscriptions';
  static const adminSubscriptionPlans = '/admin/subscription-plans';
  static const adminSubscriptionMembers = '/admin/subscription-members';
  static const referrals = '/referrals';
  static const adminReferrals = '/admin/referrals';
  static const adminAnalytics = '/admin/analytics';
  static const shop = '/shop';
  static const shopProduct = '/shop/product';
  static const shopCart = '/shop/cart';
  static const shopConfirmation = '/shop/confirmation';
  static const adminShopProducts = '/admin/shop/products';
  static const adminShopOrders = '/admin/shop/orders';
  static const events = '/events';
  static const eventsDetail = '/events/:slug';
  static const eventsConfirmation = '/events/confirmation';
  static const adminEvents = '/admin/events';
  static const adminEventsAttendees = '/admin/events/:id/attendees';
  static const services = '/services';
  static const serviceDetail = '/services/:slug';
  static const courses                = '/courses';
  static const courseDetail           = '/courses/:slug';
  static const lessonPlayer           = '/courses/:slug/lesson/:id';
  static const adminCourses           = '/admin/courses';
  static const adminCourseEditor      = '/admin/courses/:id/edit';
  static const adminCourseEnrollments = '/admin/courses/:id/enrollments';
  static const adminCompliance = '/admin/compliance';
  static const menu           = '/menu';
  static const adminMenu      = '/admin/menu';
  static const adminLocations = '/admin/locations';
  static const notFound = '/404';
}

/// AppRouter — builds the GetX route list from the active module registry.
/// Called once during app initialization.
class AppRouter {
  AppRouter._();

  static List<GetPage> buildRoutes() {
    return [...ModuleRegistry.allRoutes];
  }
}
