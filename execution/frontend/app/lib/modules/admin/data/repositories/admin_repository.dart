import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../booking/models/booking_model.dart';
import '../../../booking/models/service_model.dart';
import '../../../faq/models/faq_item_model.dart';
import '../../../blog/models/blog_post_model.dart';
import '../../../gallery/models/gallery_photo_model.dart';
import '../../../testimonials/models/testimonial_model.dart';

/// AdminRepository — data layer for the admin + staff portal.
/// All mutations go through this class; no direct Supabase calls in controllers.
class AdminRepository {
  SupabaseClient get _db => Supabase.instance.client;

  // ── Bookings (master: all; staff: own) ────────────────────────────────────
  Future<List<BookingModel>> getBookings({
    String? artistId,
    String? status,
    int limit = 50,
  }) async {
    // Apply filters before order/limit (eq not available on TransformBuilder)
    var q = _db.from('bookings').select();
    if (artistId != null) q = q.eq('artist_id', artistId);
    if (status   != null) q = q.eq('status', status);
    final rows = await q.order('start_time', ascending: false).limit(limit);
    return (rows as List)
        .map((r) => BookingModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    if (status == 'cancelled') {
      // cancel-booking handles Stripe refund, DB update, and notifications
      await _db.functions.invoke('cancel-booking', body: {
        'booking_id':    bookingId,
        'notify_client': true,
      });
      return;
    }

    await _db.from('bookings').update({'status': status}).eq('id', bookingId);

    if (status == 'confirmed') {
      _db.functions.invoke('send-notification', body: {
        'booking_id': bookingId,
        'type':       'confirmation',
      }).ignore();
    }
  }

  // ── Services ──────────────────────────────────────────────────────────────
  Future<List<ServiceModel>> getServices() async {
    final rows = await _db
        .from('services')
        .select()
        .order('category')
        .order('name');
    return (rows as List)
        .map((r) => ServiceModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> createService(Map<String, dynamic> data) async {
    await _db.from('services').insert(data);
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await _db.from('services').update(data).eq('id', id);
  }

  Future<void> toggleService(String id, bool isActive) async {
    await _db.from('services').update({'is_active': isActive}).eq('id', id);
  }

  // ── Artist ↔ Service assignments ──────────────────────────────────────────
  Future<List<String>> getArtistServiceIds(String artistId) async {
    final rows = await _db
        .from('artist_services')
        .select('service_id')
        .eq('artist_id', artistId);
    return (rows as List).map((r) => r['service_id'] as String).toList();
  }

  Future<void> setArtistServices(
      String artistId, List<String> serviceIds) async {
    await _db.from('artist_services').delete().eq('artist_id', artistId);
    if (serviceIds.isNotEmpty) {
      await _db.from('artist_services').insert(serviceIds
          .map((sid) => {'artist_id': artistId, 'service_id': sid})
          .toList());
    }
  }

  // ── Business config ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getBusinessConfig() async {
    return await _db.from('business_config').select().limit(1).single();
  }

  Future<void> updateBusinessConfig(Map<String, dynamic> data) async {
    await _db.from('business_config').update(data);
  }

  // ── Business hours ────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getBusinessHours() async {
    final rows = await _db
        .from('business_hours')
        .select()
        .order('weekday');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> updateBusinessHour(int weekday, Map<String, dynamic> data) async {
    await _db.from('business_hours').update(data).eq('weekday', weekday);
  }

  // ── Time-off ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTimeOff(String artistId) async {
    final rows = await _db
        .from('time_off')
        .select()
        .eq('artist_id', artistId)
        .gte('end_time', DateTime.now().toIso8601String())
        .order('start_time');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> addTimeOff({
    required String artistId,
    required DateTime start,
    required DateTime end,
    String? reason,
  }) async {
    await _db.from('time_off').insert({
      'artist_id': artistId,
      'start_time': start.toUtc().toIso8601String(),
      'end_time':   end.toUtc().toIso8601String(),
      'reason': reason,
    });
  }

  Future<void> deleteTimeOff(String id) async {
    await _db.from('time_off').delete().eq('id', id);
  }

  // ── Promo codes ───────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPromoCodes(String artistId) async {
    final rows = await _db
        .from('promo_codes')
        .select()
        .eq('artist_id', artistId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> createPromoCode(Map<String, dynamic> data) async {
    await _db.from('promo_codes').insert(data);
  }

  Future<void> togglePromoCode(String id, bool isActive) async {
    await _db.from('promo_codes').update({'is_active': isActive}).eq('id', id);
  }

  Future<void> deletePromoCode(String id) async {
    await _db.from('promo_codes').delete().eq('id', id);
  }

  // ── Testimonials ──────────────────────────────────────────────────────────
  Future<List<TestimonialModel>> getTestimonials() async {
    final rows = await _db
        .from('testimonials')
        .select()
        .order('display_order');
    return (rows as List)
        .map((r) => TestimonialModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> createTestimonial(Map<String, dynamic> data) async {
    await _db.from('testimonials').insert(data);
  }

  Future<void> updateTestimonial(String id, Map<String, dynamic> data) async {
    await _db.from('testimonials').update(data).eq('id', id);
  }

  Future<void> deleteTestimonial(String id) async {
    await _db.from('testimonials').delete().eq('id', id);
  }

  // ── Blog ──────────────────────────────────────────────────────────────────
  Future<List<BlogPostModel>> getBlogPosts() async {
    final rows = await _db
        .from('blog_posts')
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => BlogPostModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> createBlogPost(Map<String, dynamic> data) async {
    await _db.from('blog_posts').insert(data);
  }

  Future<void> updateBlogPost(String id, Map<String, dynamic> data) async {
    await _db.from('blog_posts').update(data).eq('id', id);
  }

  Future<void> deleteBlogPost(String id) async {
    await _db.from('blog_posts').delete().eq('id', id);
  }

  // ── Gallery ───────────────────────────────────────────────────────────────
  Future<List<GalleryPhotoModel>> getGalleryPhotos() async {
    final rows = await _db
        .from('gallery_photos')
        .select()
        .order('display_order');
    return (rows as List).map((r) {
      final m = r as Map<String, dynamic>;
      final url = _db.storage
          .from('gallery')
          .getPublicUrl(m['storage_path'] as String);
      return GalleryPhotoModel.fromMap(m, publicUrl: url);
    }).toList();
  }

  Future<void> addGalleryPhoto({
    required String storagePath,
    String? caption,
    int displayOrder = 0,
  }) async {
    await _db.from('gallery_photos').insert({
      'storage_path':  storagePath,
      'caption':       caption,
      'display_order': displayOrder,
    });
  }

  Future<void> updateGalleryPhoto(String id, Map<String, dynamic> data) async {
    await _db.from('gallery_photos').update(data).eq('id', id);
  }

  Future<void> deleteGalleryPhoto(String id, String storagePath) async {
    await _db.storage.from('gallery').remove([storagePath]);
    await _db.from('gallery_photos').delete().eq('id', id);
  }

  // ── Staff profiles (master manages display info) ──────────────────────────
  Future<List<Map<String, dynamic>>> getStaffProfiles() async {
    final rows = await _db
        .from('profiles')
        .select('id, display_name, bio, photo_url, specialties, role')
        .inFilter('role', ['master', 'staff'])
        .order('display_name');
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> updateStaffProfile(
      String id, Map<String, dynamic> data) async {
    await _db.from('profiles').update(data).eq('id', id);
  }

  // ── FAQ ───────────────────────────────────────────────────────────────────
  Future<List<FaqItemModel>> getFaqs() async {
    final rows = await _db
        .from('faqs')
        .select()
        .order('display_order');
    return (rows as List)
        .map((r) => FaqItemModel.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> createFaq(Map<String, dynamic> data) async {
    await _db.from('faqs').insert(data);
  }

  Future<void> updateFaq(String id, Map<String, dynamic> data) async {
    await _db.from('faqs').update(data).eq('id', id);
  }

  Future<void> deleteFaq(String id) async {
    await _db.from('faqs').delete().eq('id', id);
  }

  // ── CRM ───────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getClients() async {
    final rows = await _db.rpc('get_client_summary') as List;
    return List<Map<String, dynamic>>.from(rows);
  }
}
