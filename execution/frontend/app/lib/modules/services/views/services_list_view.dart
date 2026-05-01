import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/personality_theme.dart';
import '../../../../core/widgets/seo_wrapper.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/views/sections/section_shared_widgets.dart';

class ServicesListView extends StatelessWidget {
  const ServicesListView({super.key});

  @override
  Widget build(BuildContext context) {
    final pt = PersonalityTheme.fromEnv();
    final isDesktop = MediaQuery.sizeOf(context).width > ESpacing.tabletBreak;

    final servicesTitle = AppEnv.city.isNotEmpty
        ? 'Services in ${AppEnv.city} | ${AppEnv.clientName}'
        : 'Our Services | ${AppEnv.clientName}';
    final servicesDesc = AppEnv.city.isNotEmpty
        ? 'Explore our professional services in ${AppEnv.city}. Book online today.'
        : 'Explore our professional services. Book online today.';

    return SeoWrapper(
      title: servicesTitle,
      description: servicesDesc,
      canonical: '${AppEnv.siteUrl}/services',
      child: Scaffold(
        appBar: AppBar(title: const Text('Services'), centerTitle: true),
        body: Obx(() {
          final ctrl = Get.find<HomeController>();
          if (ctrl.isLoading.value && ctrl.services.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ctrl.services.isEmpty) {
            return const Center(child: Text('No services found.'));
          }

          return SingleChildScrollView(
            child: SectionWrapper(
              child: Column(
                children: [
                  const SectionHeader(
                    overline: 'Our Offerings',
                    title: 'Professional Services',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: ESpacing.xxl),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 1,
                      crossAxisSpacing: ESpacing.lg,
                      mainAxisSpacing: ESpacing.lg,
                      childAspectRatio: isDesktop ? 1.0 : 3.0,
                    ),
                    itemCount: ctrl.services.length,
                    itemBuilder: (_, i) => ServiceCard(
                      service: ctrl.services[i],
                      pt: pt,
                      onTap: () => Get.toNamed(
                        '${ERoutes.services}/${ctrl.services[i].slug}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
