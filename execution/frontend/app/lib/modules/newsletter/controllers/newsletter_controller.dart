import 'package:get/get.dart';
import '../../../shared/services/supabase_service.dart';

/// NewsletterController — manages subscribe form state.
/// Calls the send-welcome Edge Function which handles DB insert + email.
class NewsletterController extends GetxController {
  final email = ''.obs;
  final name  = ''.obs;

  final isSubmitting = false.obs;
  final isSuccess    = false.obs;
  final error        = ''.obs;

  bool get canSubmit {
    final e = email.value.trim();
    return e.contains('@') && e.contains('.');
  }

  Future<void> subscribe() async {
    if (!canSubmit) return;
    isSubmitting.value = true;
    error.value        = '';
    try {
      await SupabaseService.client.functions.invoke(
        'send-welcome',
        body: {
          'email':  email.value.trim().toLowerCase(),
          'name':   name.value.trim().isEmpty ? null : name.value.trim(),
          'source': 'website',
        },
      );
      isSuccess.value = true;
    } catch (_) {
      error.value = 'Something went wrong. Please try again.';
    } finally {
      isSubmitting.value = false;
    }
  }

  void reset() {
    email.value     = '';
    name.value      = '';
    isSuccess.value = false;
    error.value     = '';
  }
}
