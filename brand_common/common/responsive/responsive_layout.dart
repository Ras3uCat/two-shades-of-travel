import 'package:raspucat/utils/constants/exports.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.desktop,
    required this.tablet,
    required this.mobile,
  });

  final Widget desktop;
  final Widget tablet;
  final Widget mobile;

  @override
  Widget build(BuildContext context) {
    /// --- optionally, add Scaffold with a SingleChildScrollView
    return LayoutBuilder(
      builder: (_, constraints) {
        print(constraints.maxWidth);
        if (constraints.maxWidth < ESizes.mobile) {
          return mobile;
        } else if (constraints.maxWidth < ESizes.tablet) {
          return tablet;
        } else {
          return desktop;
        }
      },
    );
  }
}
