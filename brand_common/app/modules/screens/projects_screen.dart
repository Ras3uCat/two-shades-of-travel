import 'package:raspucat/utils/constants/exports.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  // Sample projects data - replace with your actual projects

  @override
  Widget build(BuildContext context) {
    final sectionAnimationController = SectionAnimationController.instance;
    final carouselController = ECarouselController.instance;

    return SectionContainer(
      paddingHorizontal: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Projects Heading
          AnimatedOnView(
            id: "projects_heading",
            controller: sectionAnimationController,
            startOffset: const Offset(0, 25),
            child: NeonText(
              text: EText.projectsHeading.toUpperCase(),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),

          const SizedBox(height: 16),

          // Projects Subtitle
          AnimatedOnView(
            id: "projects_subtitle",
            controller: sectionAnimationController,
            startOffset: const Offset(0, 50),
            child: Text(
              EText.projectsSubheading,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: EColors.textPrimary.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 48),

          // Projects Carousel
          AnimatedOnView(
            id: "projects_carousel",
            controller: sectionAnimationController,
            startOffset: const Offset(0, 100),
            child: ProjectsCarousel(controller: carouselController),
          ),
        ],
      ),
    );
  }
}
