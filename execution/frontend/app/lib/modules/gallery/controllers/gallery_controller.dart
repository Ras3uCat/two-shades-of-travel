import 'package:get/get.dart';
import '../../../shared/services/supabase_service.dart';
import '../models/gallery_photo_model.dart';

class GalleryController extends GetxController {
  final photos    = <GalleryPhotoModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final rows = await SupabaseService.client
          .from('gallery_photos')
          .select()
          .eq('is_active', true)
          .order('display_order');
      photos.value = (rows as List).map((r) {
        final m = r as Map<String, dynamic>;
        final url = SupabaseService.client.storage
            .from('gallery')
            .getPublicUrl(m['storage_path'] as String);
        return GalleryPhotoModel.fromMap(m, publicUrl: url);
      }).toList();
    } catch (_) {
      photos.value = [];
    } finally {
      isLoading.value = false;
    }
  }
}
