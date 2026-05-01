import 'package:raspucat/utils/constants/exports.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;

    final isMobile = width < ESizes.mobile;

    return SectionContainer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CenterLogo(),
            const SizedBox(height: ESizes.spaceBtwSections),
            FittedBox(
              child: NeonText(
                text: EText.heroHeading.toUpperCase(),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),

            Text(
              EText.heroSubtext.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: EColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            // NeonButton(onTap: () {}, child: Text("Contact Us")),
          ],
        ),
      ),
    );
  }
}
