import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_env.dart';

/// SupabaseService — initializes the Supabase client from AppEnv credentials.
/// Access the client anywhere via SupabaseService.client.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }

  // Auth convenience
  static User? get currentUser => client.auth.currentUser;
  static Session? get currentSession => client.auth.currentSession;
  static bool get isSignedIn => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
