import 'dart:ui' as html;

import 'package:raspucat/utils/constants/exports.dart';

class EDeviceUtils {
  /// --- INPUT DEVICES --- ///
  ///
  ///
  static double getKeybordHeight() {
    final viewInsets = MediaQuery.of(Get.context!).viewInsets;
    return viewInsets.bottom;
  }

  static Future<bool> isKeyboardVisible() async {
    final viewInsets = View.of(Get.context!).viewInsets;
    return viewInsets.bottom > 0;
  }

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  static Future<bool> isPhysicalDevice() async {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// --- DEVICE TYPE --- ///
  ///
  ///

  static bool isDesktop() {
    return GetPlatform.isDesktop;
  }

  static bool isMobile() {
    return GetPlatform.isMobile;
  }

  static bool isWeb() {
    return GetPlatform.isWeb;
    //All platforms are supported independently in web!
    //You can tell if you are running inside a browser
    //on Windows, iOS, OSX, Android, etc.
  }

  /// --- DEVICE PLATFORM --- ///
  ///
  ///

  static bool isAndroid() {
    return GetPlatform.isAndroid;
  }

  static bool isIOS() {
    return GetPlatform.isIOS;
  }

  static bool isMacOS() {
    return GetPlatform.isIOS;
  }

  static bool isWindows() {
    return GetPlatform.isIOS;
  }

  static bool isLinux() {
    return GetPlatform.isIOS;
  }

  /// --- SCREEN SIZE --- ///
  ///
  ///

  static Size getScreenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  static double getScreenHeight() {
    return MediaQuery.sizeOf(Get.context!).height;
  }

  static double getScreenWidth() {
    return MediaQuery.sizeOf(Get.context!).width;
  }

  static bool isSmallScreen() {
    return (Get.context!).width <= ESizes.mobile;
  }

  static bool isMediumScreen() {
    return (Get.context!).width > ESizes.mobile &&
        (Get.context!).width <= ESizes.tablet;
  }

  static bool isLargeScreen() {
    return (Get.context!).width > ESizes.tablet;
  }

  static void setFullScreen(bool enable) {
    SystemChrome.setEnabledSystemUIMode(
      enable ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  /// --- SCREEN ORIENTATION --- ///
  ///
  ///

  static bool isLandscapeOrientation(BuildContext context) {
    final viewInsets = View.of(context).viewInsets;
    return viewInsets.bottom == 0;
  }

  static bool isPortraitOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
    // final viewInsets = View.of(context).viewInsets;
    // return viewInsets.bottom != 0;
  }

  static Future<void> setPreferredOrientations(
    List<DeviceOrientation> orientations,
  ) async {
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// --- SYSTEM SETTINGS --- ///
  ///
  ///

  /// --- THEME MODE --- ///
  static bool isDarkMode() {
    return Theme.of(Get.context!).brightness == Brightness.dark;
  }

  /// --- STATUS BAR --- ///
  static Future<void> setStatusBarColor(Color color) async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: color),
    );
  }

  static double getStatusBarHeight() {
    return MediaQuery.of(Get.context!).padding.top;
  }

  static void hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  static void showStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  /// --- DEVICE FEEDBACK --- ///
  static void vibrate(Duration duration) {
    HapticFeedback.vibrate();
    Future.delayed(duration, () => HapticFeedback.vibrate());
  }

  /// --- NETWORK SETTINGS --- ///
  ///
  ///

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static void launchUrl(String url) async {
    try {
      if (Platform.isLinux) {
        // For Linux, use a different approach
        await Process.run('xdg-open', [url]);
      } else if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print('Could not launch $url: $e');
      throw 'Could not launch $url';
    }
  }

  /// --- OTHER SETTINGS --- ///
  ///
  ///

  static double getPixelRatio() {
    return MediaQuery.of(Get.context!).devicePixelRatio;
  }

  static double getBottomNavigationBarHeight() {
    return kBottomNavigationBarHeight;
  }

  static double getAppBarHeight() {
    return kToolbarHeight;
  }
}





// // give the current args from currentScreen
// Get.arguments

// // give name of previous route
// Get.previousRoute

// // give the raw route to access for example, rawRoute.isFirst()
// Get.rawRoute

// // give access to Routing API from GetObserver
// Get.routing

// // check if snackbar is open
// Get.isSnackbarOpen

// // check if dialog is open
// Get.isDialogOpen

// // check if bottomsheet is open
// Get.isBottomSheetOpen

// // remove one route.
// Get.removeRoute()

// // back repeatedly until the predicate returns true.
// Get.until()

// // go to next route and remove all the previous routes until the predicate returns true.
// Get.offUntil()

// // go to next named route and remove all the previous routes until the predicate returns true.
// Get.offNamedUntil()




// // Gives the current context of the Navigator.
// Get.context

// // Gives the context of the snackbar/dialog/bottomsheet in the foreground, anywhere in your code.
// Get.contextOverlay

// // If you need a changeable height/width (like Desktop or browser windows that can be scaled) you will need to use context.
// context.width
// context.height



// /// Similar to MediaQuery.of(context).padding
// context.mediaQueryPadding()

// /// Similar to MediaQuery.of(context).viewPadding
// context.mediaQueryViewPadding()

// /// Similar to MediaQuery.of(context).viewInsets;
// context.mediaQueryViewInsets()


// /// Similar to MediaQuery.of(context).devicePixelRatio;
// context.devicePixelRatio()

// /// Similar to MediaQuery.of(context).textScaleFactor;
// context.textScaleFactor()

