import 'package:get/get.dart';
import '../../../shared/services/supabase_service.dart';

class ContactController extends GetxController {
  final name    = ''.obs;
  final email   = ''.obs;
  final message = ''.obs;
  final loading = false.obs;
  final sent    = false.obs;
  final error   = ''.obs;

  bool get canSubmit =>
      name.value.trim().length >= 2 &&
      email.value.contains('@') &&
      email.value.contains('.') &&
      message.value.trim().length >= 10;

  Future<void> submit() async {
    if (!canSubmit) return;
    loading.value = true;
    error.value   = '';

    try {
      await SupabaseService.client.functions.invoke(
        'send-contact',
        body: {
          'name':    name.value.trim(),
          'email':   email.value.trim(),
          'message': message.value.trim(),
        },
      );
      sent.value = true;
    } catch (e) {
      error.value = 'Failed to send message. Please try again.';
    } finally {
      loading.value = false;
    }
  }

  void reset() {
    name.value    = '';
    email.value   = '';
    message.value = '';
    sent.value    = false;
    error.value   = '';
  }
}
