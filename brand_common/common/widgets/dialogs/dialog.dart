import 'package:raspucat/utils/constants/exports.dart';

class EDialog extends StatelessWidget {
  const EDialog({super.key, this.child = const SizedBox()});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double width = EDeviceUtils.getScreenWidth();
    double height = EDeviceUtils.getScreenHeight();
    bool isMobile = width < ESizes.mobile;
    bool isTablet = width < ESizes.tablet && width >= ESizes.mobile;

    return Container(
      margin: isMobile
          ? EdgeInsets.symmetric(
              horizontal: width * 0.1,
              vertical: height * 0.1,
            )
          : isTablet
          ? EdgeInsets.symmetric(
              horizontal: width * 0.2,
              vertical: height * 0.1,
            )
          : EdgeInsets.symmetric(
              horizontal: width * 0.3,
              vertical: height * 0.1,
            ),
      decoration: BoxDecoration(
        color: EColors.backgroundDark.withOpacity(0.7),
        borderRadius: BorderRadius.circular(ESizes.borderRadiusXl),
        border: Border.all(color: EColors.primary, width: 2),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(ESizes.borderRadiusXl),
            child: AlertDialog(
              contentPadding: const EdgeInsets.symmetric(horizontal: ESizes.md),
              insetPadding: const EdgeInsets.all(00),
              backgroundColor: Colors.transparent,
              content: SizedBox(width: isMobile ? width : width, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
