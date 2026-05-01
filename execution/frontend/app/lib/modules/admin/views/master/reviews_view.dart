import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../../core/theme/e_spacing.dart';
import '../admin_shell.dart';

class ReviewsView extends StatefulWidget {
  const ReviewsView({super.key});
  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      List rows;
      if (_showAll) {
        rows = await _db.from('reviews').select().order('created_at', ascending: false);
      } else {
        rows = await _db.from('reviews').select().eq('is_approved', false).order('created_at', ascending: false);
      }
      setState(() => _reviews = rows.cast<Map<String, dynamic>>());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _approve(String id) async {
    await _db.from('reviews').update({'is_approved': true}).eq('id', id);
    await _load();
  }

  Future<void> _delete(String id) async {
    await _db.from('reviews').delete().eq('id', id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminReviews,
      isMaster: true,
      child: Padding(
        padding: const EdgeInsets.all(ESpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Reviews', style: ETextStyles.h3),
                const Spacer(),
                Switch(
                  value: _showAll,
                  onChanged: (v) { _showAll = v; _load(); },
                  activeTrackColor: EColors.primary,
                ),
                const SizedBox(width: ESpacing.xs),
                Text('Show approved', style: ETextStyles.labelSm),
              ],
            ),
            const SizedBox(height: ESpacing.lg),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_reviews.isEmpty)
              Center(
                child: Text('No reviews to moderate.', style: ETextStyles.bodyMd),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _reviews.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _reviews[i];
                    final approved = r['is_approved'] as bool? ?? false;
                    final rating   = (r['rating'] as num?)?.toInt() ?? 0;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: ESpacing.sm, horizontal: 0),
                      title: Row(
                        children: [
                          Text(r['client_name'] as String? ?? 'Anonymous',
                              style: ETextStyles.labelSm),
                          const SizedBox(width: ESpacing.sm),
                          Row(
                            children: List.generate(5, (j) => Icon(
                              j < rating ? Icons.star : Icons.star_border,
                              size: 14,
                              color: EColors.primary,
                            )),
                          ),
                          if (approved) ...[
                            const SizedBox(width: ESpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              color: EColors.primary.withValues(alpha: 0.15),
                              child: Text('APPROVED',
                                  style: ETextStyles.labelSm
                                      .copyWith(fontSize: 10)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        r['comment'] as String? ?? '',
                        style: ETextStyles.bodyMd,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!approved)
                            TextButton(
                              onPressed: () => _approve(r['id'] as String),
                              child: Text('Approve',
                                  style: ETextStyles.labelSm
                                      .copyWith(color: EColors.primary)),
                            ),
                          TextButton(
                            onPressed: () => _delete(r['id'] as String),
                            child: Text('Delete',
                                style: ETextStyles.labelSm
                                    .copyWith(color: EColors.error)),
                          ),
                        ],
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
