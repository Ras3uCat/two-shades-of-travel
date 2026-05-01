// Tracks cookie consent and persists it across sessions via shared_preferences.
// On first visit the banner appears; once the user responds, it stays hidden.
// On web, accepting consent calls window.enableAnalytics() defined in index.html.
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../gdpr_bridge_stub.dart'
    if (dart.library.js_interop) '../gdpr_bridge_web.dart';

class GdprController extends GetxController {
  static const _key = 'gdpr_consent';

  final _accepted = false.obs;
  final _declined = false.obs;

  bool get hasResponded => _accepted.value || _declined.value;
  bool get accepted     => _accepted.value;

  @override
  void onInit() {
    super.onInit();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'accepted') _accepted.value = true;
    if (saved == 'declined') _declined.value = true;
  }

  Future<void> accept() async {
    _accepted.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, 'accepted');
    callEnableAnalytics(); // triggers analytics scripts defined in index.html
  }

  Future<void> decline() async {
    _declined.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, 'declined');
  }
}
