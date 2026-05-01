import 'package:raspucat/utils/constants/exports.dart';

class ProjectScreen extends StatelessWidget {
  final ProjectModel project;
  const ProjectScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: double.infinity,
      child: Column(
        children: [
          SizedBox(height: ESizes.spaceBtwSections),

          /// --- PROJECT TITLE --- ///
          NeonText(
            isHeadline: true,
            neonColor: EColors.textPrimary.withOpacity(0.5),
            text: project.title.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: EColors.textPrimary),
          ),
          SizedBox(height: ESizes.spaceBtwSections),

          /// --- PROJECT IMAGE CAROUSEL --- ///
          if (project.imagePaths.isNotEmpty) ...[
            _buildImageCarousel(context),
          ] else
            _buildPlaceholderImage(context),
          SizedBox(height: ESizes.spaceBtwSections),

          /// --- PROJECT DESCRIPTION --- ///
          if (project.description.isNotEmpty) ...[
            Text(
              project.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: EColors.textPrimary.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ESizes.spaceBtwSections),
          ],

          /// --- TECHNOLOGIES --- ///
          if (project.technologies.isNotEmpty) ...[
            Wrap(
              spacing: ESizes.sm,
              runSpacing: ESizes.sm,
              alignment: WrapAlignment.center,
              children: project.technologies.map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(ESizes.borderRadiusMd),
                    border: Border.all(
                      color: EColors.primary.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tech,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: EColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: ESizes.spaceBtwSections),
          ],

          /// --- ACTION BUTTONS --- ///
          if (project.githubUrl != null || project.liveUrl != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// --- CODE BUTTON --- ///
                if (project.githubUrl != null)
                  NeonButton(
                    onTap: () {
                      // Handle GitHub link
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EIcons.iconModify(EIcons.code, size: ESizes.iconSm),

                        SizedBox(width: 8),
                        Text(
                          EText.code,
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(color: EColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                if (project.githubUrl != null && project.liveUrl != null)
                  SizedBox(width: 16),
                if (project.liveUrl != null)
                  NeonButton(
                    onTap: () {
                      EDeviceUtils.launchUrl(project.liveUrl!);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EIcons.iconModify(EIcons.launch, size: ESizes.iconSm),

                        SizedBox(width: 8),
                        Text(
                          EText.live,
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(color: EColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context) {
    return Container(
      height: ESizes.imageSizeXl,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        border: Border.all(color: EColors.primary.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: EColors.primary.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        child: CarouselSlider.builder(
          itemCount: project.imagePaths.length,
          options: CarouselOptions(
            height: ESizes.imageSizeXl,

            viewportFraction: 1.0,
            enableInfiniteScroll: project.imagePaths.length > 1,
            autoPlay: project.imagePaths.length > 1,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: false,
            // aspectRatio: 16 / 9,
          ),
          itemBuilder: (context, index, realIndex) {
            return Stack(
              children: [
                Image.asset(
                  project.imagePaths[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: EColors.primary.withOpacity(0.1),
                ),
                // Image counter overlay
                if (project.imagePaths.length > 1)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: EColors.backgroundDark.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(
                          ESizes.borderRadiusMd,
                        ),
                        border: Border.all(
                          color: EColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${index + 1} / ${project.imagePaths.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: EColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      height: ESizes.imageSizeLg,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EColors.primary.withOpacity(0.2),
            EColors.secondary.withOpacity(0.2),
          ],
        ),
        border: Border.all(color: EColors.primary.withOpacity(0.3), width: 1),
      ),
      child: Center(
        child: Icon(
          Icons.code,
          size: 80,
          color: EColors.primary.withOpacity(0.6),
        ),
      ),
    );
  }
}
