import 'package:raspucat/utils/constants/exports.dart';

class EResponsiveScreen extends StatelessWidget {
  const EResponsiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      desktop: DesktopLayout(),
      tablet: TabletLayout(),
      mobile: MobileLayout(),
    );
  }
}
