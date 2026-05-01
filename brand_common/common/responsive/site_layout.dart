import 'package:raspucat/common/responsive/responsive_layout.dart';
import 'package:raspucat/common/responsive/screens/desktop_layout.dart';
import 'package:raspucat/common/responsive/screens/mobile_layout.dart';
import 'package:raspucat/common/responsive/screens/tablet_layout.dart';
import 'package:raspucat/utils/constants/exports.dart';

class ESiteLayout extends StatelessWidget {
  const ESiteLayout({
    super.key,
    this.desktop,
    this.tablet,
    this.mobile,
    this.useLayout = true,
  });
  final Widget? desktop;
  final Widget? tablet;
  final Widget? mobile;
  final bool useLayout;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        /// --- DESKTOP LAYOUT --- ///
        desktop: useLayout
            ? DesktopLayout(
                body: desktop,
              ) // Wrap desktop widget in DesktopLayout if useLayout is true
            : desktop ??
                  Container(), // Fallback to an empty container if no desktop widget is provided
        /// --- TABLET LAYOUT --- ///
        tablet: useLayout
            ? TabletLayout(
                body: tablet ?? desktop,
              ) // Wrap tablet widget in TabletLayout if useLayout is true
            : tablet ??
                  desktop ??
                  Container(), // Fallback to desktop or an empty container if no tablet widget is provided
        /// --- MOBILE LAYOUT --- ///
        mobile: useLayout
            ? MobileLayout(
                body: mobile ?? desktop,
              ) // Wrap mobile widget in MobileLayout if useLayout is true
            : mobile ??
                  desktop ??
                  Container(), // Fallback to desktop or an empty container if no mobile widget is provided
      ),
    );
  }
}
