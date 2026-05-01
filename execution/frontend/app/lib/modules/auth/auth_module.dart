import 'package:get/get.dart';
import '../_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import 'bindings/auth_binding.dart';
import 'bindings/profile_binding.dart';
import 'views/login_view.dart';
import 'views/profile_view.dart';

class AuthModule implements AppModule {
  @override
  String get moduleId => 'auth';

  @override
  NavItem? get navItem => null; // Auth is not shown in main nav

  @override
  Bindings? get binding => AuthBinding();

  @override
  List<GetPage> get routes => [
    GetPage(
      name: ERoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: ERoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}
