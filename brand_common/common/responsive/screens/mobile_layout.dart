import 'package:raspucat/utils/constants/exports.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({super.key, this.body});

  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return const DesktopLayout();
  }
}
