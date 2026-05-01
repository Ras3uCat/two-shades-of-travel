import 'package:raspucat/utils/constants/exports.dart';

class TabletLayout extends StatelessWidget {
  const TabletLayout({super.key, this.body});

  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return const DesktopLayout();
  }
}
