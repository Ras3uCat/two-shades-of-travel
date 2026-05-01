import 'package:raspucat/utils/constants/exports.dart';
import 'package:raspucat/utils/popups/loaders.dart';

class ProjectsCarousel extends StatelessWidget {
  final ECarouselController controller;

  const ProjectsCarousel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;

    final isMobile = width < ESizes.mobile;
    return Column(
      children: [
        /// --- CAROUSEL SLIDER --- ///
        ///
        ///
        Obx(() {
          final currentPage = controller.currentPage.value;

          return CarouselSlider.builder(
            carouselController: controller.carouselController,
            itemCount: controller.projects.length,
            options: CarouselOptions(
              height: ESizes.carouselHeightMd,

              enlargeCenterPage: true,
              viewportFraction: isMobile ? 0.9 : 0.4,
              enableInfiniteScroll: true,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 3),
              onPageChanged: (index, reason) {
                controller.onPageChanged(index);
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final project = controller.projects[index];
              final isSelected = currentPage == index;

              /// --- PROJECT CARD --- ///
              ///
              ///
              return ProjectCard(
                project: project,

                isSelected: isSelected,
                onTap: () {
                  ELoaders.customDialog(child: ProjectScreen(project: project));
                },
              );
            },
          );
        }),

        const SizedBox(height: ESizes.spaceBtwSections),

        /// --- NAVIGATION TRIANGLES --- ///
        ///
        ///
        Obx(() {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(controller.projects.length, (index) {
              final isActive = controller.currentPage.value == index;
              final project = controller.projects[index];
              final isHovered = controller.hoveredIndex.value == index;

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => controller.setHoveredIndex(index),
                onExit: (_) => controller.clearHover(),
                child: GestureDetector(
                  onTap: () => controller.jumpTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 8),

                    child: CustomPaint(
                      size: Size((isActive ? 24 : 16), (isActive ? 24 : 16)),
                      painter: TriangleNavigationPainter(
                        color: EColors.primary,
                        isHovered: isHovered,
                        isActive: isActive,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}
