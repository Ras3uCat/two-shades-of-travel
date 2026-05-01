import 'package:raspucat/app/modules/screens/projects_screen.dart';
import 'package:raspucat/utils/constants/exports.dart';

List<Widget> screens = [HomeScreen(), ProjectsScreen()];

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key, this.body});

  final Widget? body;

  @override
  Widget build(BuildContext context) {
    /// --- CONTROLLERS --- ///
    final scrollController = EScrollController.instance;

    /// --- METHOD 1 --- ///
    //     return Scaffold(
    //       backgroundColor: EColors.backgroundDark,
    //       body: Stack(
    //         children: [
    //           SingleChildScrollView(
    //             controller: scrollController.scrollController,
    //             child: Column(children: [HomeScreen(), ProjectsScreen()]),
    //           ),
    //           BackgroundTriangles(),
    //         ],
    //       ),
    //     );
    //   }
    // }

    /// --- METHOD 2 --- ///
    return Scaffold(
      backgroundColor: EColors.backgroundDark,
      body: SingleChildScrollView(
        controller: scrollController.scrollController,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * screens.length,
          // width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              BackgroundTriangles(),
              Column(children: screens),
              // BackgroundTriangles(),
            ],
          ),
        ),
      ),
    );
  }
}
