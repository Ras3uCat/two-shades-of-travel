import 'package:raspucat/app/modules/screens/bingequest_legal_screen.dart';
import 'package:raspucat/utils/constants/exports.dart';

class AppRoutes {
  static final pages = [
    GetPage(name: ERoutes.home, page: () => EResponsiveScreen()),
    GetPage(name: ERoutes.bingeQuestLegal, page: () => const BingeQuestLegalScreen()),
  ];
}

// TO USE:
//    onTap: () {
//               Get.toNamed(ERoutes.home);
//             },
