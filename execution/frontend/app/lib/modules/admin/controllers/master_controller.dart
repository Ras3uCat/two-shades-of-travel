import 'package:get/get.dart';
import '../../../shared/services/supabase_service.dart';
import '../../blog/models/blog_post_model.dart';
import '../../booking/models/booking_model.dart';
import '../../booking/models/service_model.dart';
import '../../faq/models/faq_item_model.dart';
import '../../gallery/models/gallery_photo_model.dart';
import '../../testimonials/models/testimonial_model.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/calendar_token_repository.dart';

/// MasterController — data + actions for the master admin dashboard.
/// Handles bookings overview, service CRUD, and business config.
class MasterController extends GetxController {
  final AdminRepository _repo = Get.find<AdminRepository>();

  // ── State ─────────────────────────────────────────────────────────────────
  final isLoading  = false.obs;
  final error      = RxnString();

  // ── Bookings ──────────────────────────────────────────────────────────────
  final bookings       = <BookingModel>[].obs;
  final statusFilter   = RxnString();    // null = all
  final artistFilter   = RxnString();    // null = all

  // ── Services ──────────────────────────────────────────────────────────────
  final services = <ServiceModel>[].obs;

  // ── FAQ ───────────────────────────────────────────────────────────────────
  final faqs = <FaqItemModel>[].obs;

  // ── Blog ──────────────────────────────────────────────────────────────────
  final blogPosts = <BlogPostModel>[].obs;

  // ── Gallery ───────────────────────────────────────────────────────────────
  final galleryPhotos = <GalleryPhotoModel>[].obs;

  // ── Testimonials ──────────────────────────────────────────────────────────
  final testimonials = <TestimonialModel>[].obs;

  // ── Staff profiles ────────────────────────────────────────────────────────
  final staffProfiles = <Map<String, dynamic>>[].obs;

  // ── CRM clients ───────────────────────────────────────────────────────────
  final clients = <Map<String, dynamic>>[].obs;

  // ── Business config + hours ───────────────────────────────────────────────
  final config       = <String, dynamic>{}.obs;
  final businessHours = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _repo.getBookings(status: statusFilter.value, artistId: artistFilter.value),
        _repo.getServices(),
        _repo.getTestimonials(),
        _repo.getFaqs(),
        _repo.getGalleryPhotos(),
        _repo.getBlogPosts(),
        _repo.getBusinessConfig(),
        _repo.getBusinessHours(),
        _repo.getStaffProfiles(),
      ]);
      bookings.value      = results[0] as List<BookingModel>;
      services.value      = results[1] as List<ServiceModel>;
      testimonials.value  = results[2] as List<TestimonialModel>;
      faqs.value          = results[3] as List<FaqItemModel>;
      galleryPhotos.value = results[4] as List<GalleryPhotoModel>;
      blogPosts.value     = results[5] as List<BlogPostModel>;
      config.value        = results[6] as Map<String, dynamic>;
      businessHours.value = results[7] as List<Map<String, dynamic>>;
      staffProfiles.value = results[8] as List<Map<String, dynamic>>;
    } catch (e) {
      error.value = 'Failed to load dashboard data.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Bookings ──────────────────────────────────────────────────────────────
  Future<void> applyFilters({String? status, String? artistId}) async {
    statusFilter.value = status;
    artistFilter.value = artistId;
    await _refreshBookings();
  }

  Future<void> _refreshBookings() async {
    try {
      bookings.value = await _repo.getBookings(
          status: statusFilter.value, artistId: artistFilter.value);
    } catch (_) {}
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _repo.updateBookingStatus(bookingId, status);
    await _refreshBookings();
  }

  // ── CRM ───────────────────────────────────────────────────────────────────
  Future<void> loadClients() async {
    try {
      clients.value = await _repo.getClients();
    } catch (_) {}
  }

  // ── Staff profiles ────────────────────────────────────────────────────────
  Future<void> updateStaffProfile(
      String id, Map<String, dynamic> data) async {
    await _repo.updateStaffProfile(id, data);
    staffProfiles.value = await _repo.getStaffProfiles();
  }

  // ── Services ──────────────────────────────────────────────────────────────
  Future<void> createService(Map<String, dynamic> data) async {
    await _repo.createService(data);
    services.value = await _repo.getServices();
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await _repo.updateService(id, data);
    services.value = await _repo.getServices();
  }

  Future<void> toggleService(String id, bool isActive) async {
    await _repo.toggleService(id, isActive);
    services.value = await _repo.getServices();
  }

  // ── Blog ──────────────────────────────────────────────────────────────────
  Future<void> createBlogPost(Map<String, dynamic> data) async {
    await _repo.createBlogPost(data);
    blogPosts.value = await _repo.getBlogPosts();
  }

  Future<void> updateBlogPost(String id, Map<String, dynamic> data) async {
    await _repo.updateBlogPost(id, data);
    blogPosts.value = await _repo.getBlogPosts();
  }

  Future<void> deleteBlogPost(String id) async {
    await _repo.deleteBlogPost(id);
    blogPosts.value = await _repo.getBlogPosts();
  }

  // ── Gallery ───────────────────────────────────────────────────────────────
  Future<void> addGalleryPhoto({
    required String storagePath,
    String? caption,
    int displayOrder = 0,
  }) async {
    await _repo.addGalleryPhoto(
      storagePath: storagePath,
      caption: caption,
      displayOrder: displayOrder,
    );
    galleryPhotos.value = await _repo.getGalleryPhotos();
  }

  Future<void> updateGalleryPhoto(String id, Map<String, dynamic> data) async {
    await _repo.updateGalleryPhoto(id, data);
    galleryPhotos.value = await _repo.getGalleryPhotos();
  }

  Future<void> deleteGalleryPhoto(String id, String storagePath) async {
    await _repo.deleteGalleryPhoto(id, storagePath);
    galleryPhotos.value = await _repo.getGalleryPhotos();
  }

  // ── FAQ ───────────────────────────────────────────────────────────────────
  Future<void> createFaq(Map<String, dynamic> data) async {
    await _repo.createFaq(data);
    faqs.value = await _repo.getFaqs();
  }

  Future<void> updateFaq(String id, Map<String, dynamic> data) async {
    await _repo.updateFaq(id, data);
    faqs.value = await _repo.getFaqs();
  }

  Future<void> deleteFaq(String id) async {
    await _repo.deleteFaq(id);
    faqs.value = await _repo.getFaqs();
  }

  // ── Testimonials ──────────────────────────────────────────────────────────
  Future<void> createTestimonial(Map<String, dynamic> data) async {
    await _repo.createTestimonial(data);
    testimonials.value = await _repo.getTestimonials();
  }

  Future<void> updateTestimonial(String id, Map<String, dynamic> data) async {
    await _repo.updateTestimonial(id, data);
    testimonials.value = await _repo.getTestimonials();
  }

  Future<void> deleteTestimonial(String id) async {
    await _repo.deleteTestimonial(id);
    testimonials.value = await _repo.getTestimonials();
  }

  // ── Business config ───────────────────────────────────────────────────────
  Future<void> saveConfig(Map<String, dynamic> data) async {
    await _repo.updateBusinessConfig(data);
    config.value = await _repo.getBusinessConfig();
  }

  Future<void> saveBusinessHour(int weekday, Map<String, dynamic> data) async {
    await _repo.updateBusinessHour(weekday, data);
    businessHours.value = await _repo.getBusinessHours();
  }

  // ── Calendar tokens (admin) ───────────────────────────────────────────────
  Future<String?> getStaffCalendarToken(String staffId) =>
      Get.find<CalendarTokenRepository>().getToken(staffId);

  Future<String> regenerateStaffCalendarToken(String staffId) =>
      Get.find<CalendarTokenRepository>().regenerateToken(staffId);

  // ── Computed ──────────────────────────────────────────────────────────────
  List<BookingModel> get upcomingBookings => bookings
      .where((b) => b.startTime.isAfter(DateTime.now()))
      .toList();

  Map<String, List<ServiceModel>> get servicesByCategory {
    final map = <String, List<ServiceModel>>{};
    for (final svc in services) {
      (map[svc.category] ??= []).add(svc);
    }
    return map;
  }

  // ── Stripe Invoicing ──────────────────────────────────────────────────────
  Future<void> sendStripeInvoice(String bookingId) async {
    try {
      final res = await SupabaseService.client.functions.invoke(
        'send-stripe-invoice',
        body: {'booking_id': bookingId},
      );
      final data = res.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        Get.snackbar('Error', data!['error'].toString());
        return;
      }
      Get.snackbar('Invoice sent', data?['invoice_url'] as String? ?? 'Invoice emailed to client');
      await loadAll();
    } catch (_) {
      Get.snackbar('Error', 'Could not send invoice');
    }
  }

  // ── PDF Invoicing ─────────────────────────────────────────────────────────
  Future<void> sendInvoice(String bookingId) async {
    try {
      final res = await SupabaseService.client.functions.invoke(
        'generate-invoice',
        body: {'booking_id': bookingId},
      );
      final data = res.data as Map<String, dynamic>?;
      if (data?['error'] != null) {
        Get.snackbar('Error', data!['error'].toString());
        return;
      }
      Get.snackbar('Invoice sent', 'PDF invoice emailed to client');
      await loadAll();
    } catch (_) {
      Get.snackbar('Error', 'Could not generate invoice');
    }
  }

  // ── Compliance ────────────────────────────────────────────────────────────
  /// Hard-deletes all data for [email] across the platform (GDPR forget).
  /// Returns the deletion summary from the forget-user Edge Function.
  Future<Map<String, dynamic>> forgetUser(String email) async {
    final res = await SupabaseService.client.functions.invoke(
      'forget-user',
      body: {'email': email},
    );
    final data = res.data as Map<String, dynamic>?;
    if (data?['deleted'] != null) {
      return data!['deleted'] as Map<String, dynamic>;
    }
    throw Exception(data?['error'] ?? 'forget-user failed');
  }
}
