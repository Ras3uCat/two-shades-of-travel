class GalleryPhotoModel {
  final String  id;
  final String  storagePath;
  final String? caption;
  final int     displayOrder;
  final bool    isActive;
  final String  publicUrl;

  const GalleryPhotoModel({
    required this.id,
    required this.storagePath,
    this.caption,
    required this.displayOrder,
    required this.isActive,
    required this.publicUrl,
  });

  factory GalleryPhotoModel.fromMap(
    Map<String, dynamic> map, {
    required String publicUrl,
  }) {
    return GalleryPhotoModel(
      id:           map['id']            as String,
      storagePath:  map['storage_path']  as String,
      caption:      map['caption']       as String?,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      isActive:     map['is_active']     as bool? ?? true,
      publicUrl:    publicUrl,
    );
  }
}
