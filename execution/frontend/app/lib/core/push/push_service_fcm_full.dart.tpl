// Real FCM implementation — deployed by deliver.sh when FCM_ENABLED=true.
// Requires: firebase_core + firebase_messaging in pubspec.yaml.
// deliver.sh runs: flutter pub add firebase_core firebase_messaging
//                  cp push_service_fcm_full.dart.tpl push_service_fcm.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_env.dart';
import '../../shared/services/supabase_service.dart';

/// Requests FCM permission and saves the token to push_subscriptions.
/// Called once on app launch. Silent no-op on web or when FCM_ENABLED=false.
Future<void> requestAndSavePush(String clientEmail) async {
  if (kIsWeb || !AppEnv.fcmEnabled) return;
  try {
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await SupabaseService.client.functions.invoke(
      'save-push-subscription',
      body: { 'fcm_token': token, 'client_email': clientEmail },
    );

    // Refresh token when Firebase rotates it
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await SupabaseService.client.functions.invoke(
          'save-push-subscription',
          body: { 'fcm_token': newToken, 'client_email': clientEmail },
        );
      } catch (_) {}
    });
  } catch (_) {
    // Push is non-critical — fail silently
  }
}

/// Registers FCM tap handlers — call once in main() after Firebase.initializeApp().
/// Routes notification taps into the existing deep-link handler.
void registerFcmTapHandlers(void Function(String url) handleDeepLink) {
  // App was CLOSED and user tapped notification
  FirebaseMessaging.instance.getInitialMessage().then((msg) {
    final url = msg?.data['url'] as String?;
    if (url != null && url.isNotEmpty) handleDeepLink(url);
  });

  // App was BACKGROUNDED and user tapped notification
  FirebaseMessaging.onMessageOpenedApp.listen((msg) {
    final url = msg.data['url'] as String?;
    if (url != null && url.isNotEmpty) handleDeepLink(url);
  });
}
