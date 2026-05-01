import 'package:get/get.dart';
import '../../../core/config/app_env.dart';
import '../../../shared/services/supabase_service.dart';
import '../../booking/models/artist_model.dart';
import '../../booking/models/service_model.dart';

/// HomeController — loads all dynamic page content for the home view.
/// Sources: business_config (copy/images), services table, profiles table.
class HomeController extends GetxController {
  final isLoading    = true.obs;
  final content      = <String, dynamic>{}.obs;   // business_config row
  final services     = <ServiceModel>[].obs;       // active services for homepage grid
  final teamMembers  = <ArtistModel>[].obs;        // staff profiles for team section

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadContent(),
        _loadServices(),
        _loadTeam(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadContent() async {
    try {
      final row = await SupabaseService.client
          .from('business_config')
          .select()
          .limit(1)
          .single();
      content.value = Map<String, dynamic>.from(row as Map);
    } catch (_) {}
  }

  Future<void> _loadServices() async {
    if (!AppEnv.moduleEnabled('booking') && !AppEnv.moduleEnabled('services')) {
      return;
    }
    try {
      final rows = await SupabaseService.client
          .from('services')
          .select()
          .eq('is_active', true)
          .order('category')
          .order('name');
      services.value = (rows as List)
          .map((r) => ServiceModel.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  Future<void> _loadTeam() async {
    try {
      final rows = await SupabaseService.client
          .from('profiles')
          .select('id, display_name, bio, photo_url, specialties, role')
          .inFilter('role', ['master', 'staff'])
          .order('display_name');
      teamMembers.value = (rows as List).map((r) {
        final map = Map<String, dynamic>.from(r as Map)
          ..['service_ids'] = <String>[];
        return ArtistModel.fromMap(map);
      }).toList();
    } catch (_) {}
  }

  // ── Typed getters with sensible fallbacks ─────────────────────────────────
  String get heroImageUrl    => content['hero_image_url']    as String? ?? '';
  String get heroOverline    => content['hero_overline']     as String? ?? '';
  String get heroTagline     => content['hero_tagline']      as String? ?? '';
  String get servicesOverline => content['services_overline'] as String? ?? 'What We Offer';
  String get servicesTitle   => content['services_title']    as String? ?? 'Our Services';
  String get servicesSubtitle => content['services_subtitle'] as String? ?? '';
  String get ctaTitle        => content['cta_title']         as String? ?? 'Ready to Get Started?';
  String get ctaButtonLabel  => content['cta_button_label']  as String? ?? 'Book Your Appointment';
}
