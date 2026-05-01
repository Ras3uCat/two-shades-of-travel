import 'package:raspucat/utils/constants/exports.dart';

class ELoaders {
  static void customDialog({
    Widget child = const SizedBox(),
    Color barrierColor = EColors.backgroundDark,
    bool isDismissable = true,
    bool isFullScreen = false,
  }) {
    showDialog(
      context: Get.context!,
      barrierDismissible: isDismissable,
      barrierColor: (barrierColor == Colors.transparent)
          ? barrierColor
          : barrierColor.withOpacity(0.7),
      builder: (context) {
        final dialog = isFullScreen
            ? Dialog.fullscreen(child: child)
            : EDialog(child: child);

        return dialog;
      },
    );
  }

  static void showSnackBar(String message) {
    ScaffoldMessenger.of(
      Get.context!,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static hideSnackBar() =>
      ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();

  static showSnackBarCustom({
    required message,
    elevation = 0.0,
    duration = 3,
    color = Colors.transparent,
  }) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: elevation,
        duration: Duration(seconds: duration),
        backgroundColor: color,
        content: Container(
          width: EDeviceUtils.getScreenWidth() * 0.8,
          padding: const EdgeInsets.all(ESizes.md),
          margin: const EdgeInsets.symmetric(horizontal: ESizes.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
            color: EDeviceUtils.isDarkMode()
                ? EColors.darkGrey.withOpacity(0.9)
                : EColors.grey.withOpacity(0.9),
          ),
          child: Center(
            child: Text(
              message,
              style: Theme.of(Get.context!).textTheme.labelLarge,
            ),
          ),
        ),
      ),
    );
  }

  static showSnackBarSuccess({title = 'Success', message = '', duration = 5}) {
    Get.snackbar(
      title,
      message,
      isDismissible: false,
      shouldIconPulse: true,
      colorText: EColors.textWhite,
      backgroundColor: EColors.secondary,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(ESizes.md),
      icon: EIcons.success,
    );
  }

  static showSnackBarWarning({required title, message = ' ', duration = 3}) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: EColors.textPrimary,
      backgroundColor: EColors.tertiary,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(ESizes.md),
      icon: EIcons.warning,
    );
  }

  static showSnackBarError({required title, message = ' ', duration = 3}) {
    Get.snackbar(
      title,
      message,
      isDismissible: true,
      shouldIconPulse: true,
      colorText: EColors.textPrimary,
      backgroundColor: EColors.error,
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: duration),
      margin: const EdgeInsets.all(ESizes.md),
      icon: EIcons.error,
    );
  }

  static void showAlert(String title, String message) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
