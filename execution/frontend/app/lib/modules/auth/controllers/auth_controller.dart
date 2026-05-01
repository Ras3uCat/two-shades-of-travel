import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_env.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/services/supabase_service.dart';

class AuthController extends GetxController {
  final _user     = Rxn<User>();
  final _role     = ''.obs;
  final _loading  = false.obs;
  final _error    = ''.obs;

  User?   get user      => _user.value;
  String  get role      => _role.value;
  bool    get isLoading => _loading.value;
  String  get error     => _error.value;
  bool    get isSignedIn => _user.value != null;
  bool    get isMaster  => _role.value == 'master';
  bool    get isStaff   => _role.value == 'staff';

  @override
  void onInit() {
    super.onInit();
    _user.value = SupabaseService.currentUser;
    if (_user.value != null) _loadRole();

    SupabaseService.authStateChanges.listen((state) {
      _user.value = state.session?.user;
      if (_user.value != null) {
        _loadRole();
      } else {
        _role.value = '';
      }
    });
  }

  Future<void> _loadRole() async {
    try {
      final data = await SupabaseService.client
          .from('profiles')
          .select('role')
          .eq('id', _user.value!.id)
          .single();
      _role.value = (data['role'] as String?) ?? '';
    } catch (_) {
      _role.value = '';
    }
  }

  Future<void> signIn(String email, String password) async {
    _loading.value = true;
    _error.value = '';
    try {
      await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _redirectByRole();
    } on AuthException catch (e) {
      _error.value = e.message;
    } catch (_) {
      _error.value = 'An unexpected error occurred.';
    } finally {
      _loading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    _loading.value = true;
    _error.value = '';
    try {
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '${AppEnv.siteUrl}${ERoutes.auth}',
      );
    } on AuthException catch (e) {
      _error.value = e.message;
    } catch (_) {
      _error.value = 'Google sign-in failed. Please try again.';
    } finally {
      _loading.value = false;
    }
  }

  Future<void> signInWithApple() async {
    _loading.value = true;
    _error.value = '';
    try {
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: '${AppEnv.siteUrl}${ERoutes.auth}',
      );
    } on AuthException catch (e) {
      _error.value = e.message;
    } catch (_) {
      _error.value = 'Apple sign-in failed. Please try again.';
    } finally {
      _loading.value = false;
    }
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
    Get.offAllNamed(ERoutes.home);
  }

  void _redirectByRole() {
    if (isMaster) {
      Get.offAllNamed(ERoutes.admin);
    } else if (isStaff) {
      Get.offAllNamed(ERoutes.staff);
    } else {
      Get.offAllNamed(ERoutes.home);
    }
  }

  /// Guards a route — redirects to login if not signed in.
  void requireAuth() {
    if (!isSignedIn) Get.offAllNamed(ERoutes.login);
  }

  /// Guards a route — redirects home if not master.
  void requireMaster() {
    if (!isMaster) Get.offAllNamed(ERoutes.home);
  }

  /// Guards a route — redirects home if not staff or master.
  void requireStaff() {
    if (!isStaff && !isMaster) Get.offAllNamed(ERoutes.home);
  }
}
