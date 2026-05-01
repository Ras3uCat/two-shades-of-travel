import 'package:raspucat/utils/constants/exports.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback? onTap;
  final bool isSelected;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.isSelected = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ESizes.carouselWidth,
      margin: const EdgeInsets.symmetric(
        horizontal: ESizes.md,
        vertical: ESizes.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EColors.backgroundDark.withOpacity(0.01),
            EColors.backgroundDark,
          ],
        ),
        border: Border.all(color: EColors.primary.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: EColors.primary.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ESizes.borderRadiusLg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(ESizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// --- PROJECT IMAGE --- ///
                  Container(
                    height: ESizes.imageSizeLg,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        ESizes.borderRadiusLg,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          EColors.primary.withOpacity(0.2),
                          EColors.secondary.withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: project.imagePaths.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ESizes.borderRadiusLg,
                            ),
                            child: Stack(
                              children: [
                                Image.asset(
                                  project.imagePaths.first,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: EColors.primary.withOpacity(0.1),
                                ),
                              ],
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.code,
                              size: 80,
                              color: EColors.primary.withOpacity(0.6),
                            ),
                          ),
                  ),

                  const SizedBox(height: ESizes.spaceBtwInputFields),

                  /// --- PROJECT TITLE --- ///
                  NeonText(
                    isHeadline: false,
                    neonColor: EColors.textPrimary.withOpacity(0.5),
                    text: project.title.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: EColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: ESizes.spaceBtwInputFields),

                  /// --- TECHNOLOGIES --- ///
                  Wrap(
                    spacing: ESizes.sm,
                    runSpacing: ESizes.sm,
                    children: project.technologies.take(3).map((tech) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          // color: EColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            ESizes.borderRadiusMd,
                          ),
                          border: Border.all(
                            color: EColors.primary.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tech,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: EColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Project Description - Only show if card is selected
                  if (isSelected) ...[
                    const SizedBox(height: ESizes.spaceBtwInputFields / 2),
                    AutoSizeText(
                      project.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: EColors.textPrimary.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // const SizedBox(height: ESizes.spaceBtwInputFields),
                  ],
                  // const SizedBox(height: 20),

                  // // Action Buttons
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     if (githubUrl != null)
                  //       Expanded(
                  //         child: NeonButton(
                  //           width: 150,
                  //           onTap: () {
                  //             // Handle GitHub link
                  //           },
                  //           child: Row(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Icon(
                  //                 Icons.code,
                  //                 size: 16,
                  //                 color: EColors.textPrimary,
                  //               ),
                  //               const SizedBox(width: 8),
                  //               Text(
                  //                 'Code',
                  //                 style: Theme.of(context).textTheme.bodySmall
                  //                     ?.copyWith(color: EColors.textPrimary),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),

                  //     if (githubUrl != null && liveUrl != null)
                  //       const SizedBox(width: 12),

                  //     if (liveUrl != null)
                  //       Expanded(
                  //         child: NeonButton(
                  //           onTap: () {
                  //             // Handle live link
                  //           },
                  //           child: Row(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Icon(
                  //                 Icons.launch,
                  //                 size: 16,
                  //                 color: EColors.textPrimary,
                  //               ),
                  //               const SizedBox(width: 8),
                  //               Text(
                  //                 'Live',
                  //                 style: Theme.of(context).textTheme.bodySmall
                  //                     ?.copyWith(color: EColors.textPrimary),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
