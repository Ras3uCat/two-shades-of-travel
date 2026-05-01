import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../../core/theme/e_spacing.dart';

class ReviewView extends StatefulWidget {
  const ReviewView({super.key});
  @override
  State<ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<ReviewView> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _submitted = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final bookingId = Get.parameters['booking_id'];
    final token     = Get.parameters['token'];
    if (bookingId == null || token == null || bookingId.isEmpty || token.isEmpty) {
      setState(() => _error = 'Invalid review link.');
      return;
    }
    if (_rating == 0) {
      setState(() => _error = 'Please select a rating.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.functions.invoke('submit-review', body: {
        'booking_id': bookingId,
        'token':      token,
        'rating':     _rating,
        if (_comment.text.trim().isNotEmpty) 'comment': _comment.text.trim(),
      });
      setState(() => _submitted = true);
    } catch (_) {
      setState(() => _error = 'This review link is invalid or has already been used.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = Get.parameters['booking_id'];
    final token     = Get.parameters['token'];
    final invalid   = bookingId == null || token == null ||
        bookingId.isEmpty || token.isEmpty;

    return Scaffold(
      appBar: AppBar(backgroundColor: EColors.surface, elevation: 0),
      backgroundColor: EColors.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(ESpacing.xl),
            child: invalid
                ? Text('Invalid review link.', style: ETextStyles.bodyMd)
                : _submitted
                    ? const _ThankYou()
                    : _Form(
                        rating:   _rating,
                        comment:  _comment,
                        loading:  _loading,
                        error:    _error,
                        onRate:   (r) => setState(() => _rating = r),
                        onSubmit: _submit,
                      ),
          ),
        ),
      ),
    );
  }
}

class _ThankYou extends StatelessWidget {
  const _ThankYou();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.check_circle_outline, size: 64, color: EColors.primary),
      const SizedBox(height: ESpacing.lg),
      Text('Thank you for your review!', style: ETextStyles.h3,
          textAlign: TextAlign.center),
      const SizedBox(height: ESpacing.sm),
      Text('Your feedback helps us improve.', style: ETextStyles.bodyMd,
          textAlign: TextAlign.center),
    ],
  );
}

class _Form extends StatelessWidget {
  const _Form({
    required this.rating,
    required this.comment,
    required this.loading,
    required this.error,
    required this.onRate,
    required this.onSubmit,
  });
  final int rating;
  final TextEditingController comment;
  final bool loading;
  final String? error;
  final ValueChanged<int> onRate;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Leave a Review', style: ETextStyles.h3),
      const SizedBox(height: ESpacing.lg),
      Text('Your rating', style: ETextStyles.inputLabel),
      const SizedBox(height: ESpacing.sm),
      Row(
        children: List.generate(5, (i) => IconButton(
          icon: Icon(
            i < rating ? Icons.star : Icons.star_border,
            color: EColors.primary,
            size: 36,
          ),
          onPressed: () => onRate(i + 1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 20,
        )),
      ),
      const SizedBox(height: ESpacing.lg),
      TextField(
        controller: comment,
        maxLines: 4,
        style: ETextStyles.inputText,
        decoration: InputDecoration(
          hintText: 'Share your experience... (optional)',
          hintStyle: ETextStyles.inputLabel,
          border: const OutlineInputBorder(),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: ESpacing.sm),
        Text(error!, style: ETextStyles.bodyMd.copyWith(color: EColors.error)),
      ],
      const SizedBox(height: ESpacing.xl),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: EColors.primary,
            foregroundColor: EColors.secondary,
            padding: const EdgeInsets.symmetric(vertical: ESpacing.md),
            shape: const RoundedRectangleBorder(),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('SUBMIT REVIEW'),
        ),
      ),
    ],
  );
}
