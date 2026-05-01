import 'dart:convert';
import 'dart:js_interop';
import '../../core/config/app_env.dart';
import '../../shared/services/supabase_service.dart';

// Calls the _pushSubscribe JS helper defined in index.html.tpl.
// Returns subscription JSON string or null on failure / permission denied.
@JS('_pushSubscribe')
external JSPromise<JSString?> _pushSubscribe(JSString vapidKey);

/// Requests browser push permission and saves the subscription to Supabase.
/// Silent no-op if permission denied, VAPID key missing, or any error occurs.
Future<void> requestAndSavePush(String clientEmail) async {
  try {
    final vapidKey = AppEnv.vapidPublicKey;
    if (vapidKey.isEmpty) return;

    final resultJs = await _pushSubscribe(vapidKey.toJS).toDart;
    if (resultJs == null) return;

    final raw = resultJs.toDart;
    final data = json.decode(raw) as Map<String, dynamic>;

    final endpoint  = data['endpoint']  as String?;
    final p256dh    = data['p256dh']    as String?;
    final auth      = data['auth']      as String?;
    final userAgent = data['userAgent'] as String?;
    if (endpoint == null || p256dh == null || auth == null) return;

    await SupabaseService.client.functions.invoke(
      'save-push-subscription',
      body: {
        'endpoint':     endpoint,
        'p256dh':       p256dh,
        'auth_key':     auth,
        'user_agent':   userAgent,
        'client_email': clientEmail,
      },
    );
  } catch (_) {
    // Push subscription is non-critical — fail silently
  }
}
