import 'package:raspucat/utils/constants/exports.dart';

class ENavBar extends StatelessWidget {
  const ENavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navItems = ["Projects", "Blog", "Contact"];
    return Positioned(
      top: 20,
      right: 40,
      child: Row(
        // children: navItems.map((item) => ENavItem(title: item)).toList(),
      ),
    );
  }
}
