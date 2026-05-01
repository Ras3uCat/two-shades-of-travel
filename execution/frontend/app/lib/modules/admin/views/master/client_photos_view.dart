import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../../core/theme/e_spacing.dart';
import '../admin_shell.dart';

class ClientPhotosView extends StatefulWidget {
  const ClientPhotosView({super.key});
  @override
  State<ClientPhotosView> createState() => _ClientPhotosViewState();
}

class _ClientPhotosViewState extends State<ClientPhotosView> {
  final _db          = Supabase.instance.client;
  final _pathCtrl    = TextEditingController();
  final _bookingCtrl = TextEditingController();
  List<Map<String, dynamic>> _photos = [];
  // storagePath -> signed URL
  final Map<String, String> _signedUrls = {};
  bool _loading = true;
  bool _isBefore = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    _bookingCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _db
          .from('client_photos')
          .select('id, storage_path, is_before, booking_id, created_at')
          .order('created_at', ascending: false)
          .limit(50);
      final photos = (rows as List).cast<Map<String, dynamic>>();
      // Fetch signed URLs for each unique path
      final urls = <String, String>{};
      for (final p in photos) {
        final path = p['storage_path'] as String;
        if (!urls.containsKey(path)) {
          try {
            final url = await _db.storage
                .from('client-photos')
                .createSignedUrl(path, 3600);
            urls[path] = url;
          } catch (_) {
            urls[path] = '';
          }
        }
      }
      setState(() {
        _photos = photos;
        _signedUrls
          ..clear()
          ..addAll(urls);
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final path      = _pathCtrl.text.trim();
    final bookingId = _bookingCtrl.text.trim();
    if (path.isEmpty || bookingId.isEmpty) return;
    await _db.from('client_photos').insert({
      'storage_path': path,
      'booking_id':   bookingId,
      'is_before':    _isBefore,
    });
    _pathCtrl.clear();
    _bookingCtrl.clear();
    await _load();
  }

  Future<void> _delete(String id) async {
    await _db.from('client_photos').delete().eq('id', id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminClientPhotos,
      isMaster: true,
      child: Padding(
        padding: const EdgeInsets.all(ESpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client Photos', style: ETextStyles.h3),
            const SizedBox(height: ESpacing.lg),
            Text('Add Photo', style: ETextStyles.labelSm),
            const SizedBox(height: ESpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _bookingCtrl,
                    style: ETextStyles.inputText,
                    decoration: const InputDecoration(
                      labelText: 'Booking ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: ESpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _pathCtrl,
                    style: ETextStyles.inputText,
                    decoration: const InputDecoration(
                      labelText: 'Storage path',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: ESpacing.sm),
                Row(
                  children: [
                    Checkbox(
                      value: _isBefore,
                      onChanged: (v) =>
                          setState(() => _isBefore = v ?? true),
                      activeColor: EColors.primary,
                    ),
                    Text('Before', style: ETextStyles.labelSm),
                  ],
                ),
                const SizedBox(width: ESpacing.sm),
                ElevatedButton(
                  onPressed: _add,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EColors.primary,
                    foregroundColor: EColors.secondary,
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: const Text('ADD'),
                ),
              ],
            ),
            const SizedBox(height: ESpacing.lg),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_photos.isEmpty)
              Center(
                child: Text('No photos yet.', style: ETextStyles.bodyMd),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _photos.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p     = _photos[i];
                    final label = (p['is_before'] as bool? ?? true)
                        ? 'BEFORE'
                        : 'AFTER';
                    final path    = p['storage_path'] as String;
                    final url     = _signedUrls[path] ?? '';
                    final bId     = p['booking_id'] as String;
                    final preview = bId.length >= 8
                        ? '${bId.substring(0, 8)}...'
                        : bId;
                    return ListTile(
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: url.isEmpty
                            ? const Icon(Icons.broken_image)
                            : Image.network(
                                url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.broken_image),
                              ),
                      ),
                      title: Text(
                        '$label  •  $path',
                        style: ETextStyles.labelSm,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Booking: $preview',
                        style: ETextStyles.bodyMd,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(p['id'] as String),
                        color: EColors.error,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
