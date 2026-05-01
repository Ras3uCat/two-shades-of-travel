import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../../../../core/config/app_env.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../../../core/widgets/seo_wrapper.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/views/sections/section_shared_widgets.dart';

class ServiceDetailView extends StatelessWidget {
  const ServiceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final slug = Get.parameters['slug'];

    return Obx(() {
      final ctrl = Get.find<HomeController>();
      final service = ctrl.services.firstWhereOrNull((s) => s.slug == slug);

      if (ctrl.isLoading.value && service == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (service == null) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('Service not found')),
        );
      }

      // JSON-LD: schema.org/Service with full provider address
      final provider = <String, dynamic>{
        '@type': 'LocalBusiness',
        'name': AppEnv.clientName,
        'url': AppEnv.siteUrl,
        if (AppEnv.phone.isNotEmpty) 'telephone': AppEnv.phone,
        if (AppEnv.street.isNotEmpty)
          'address': {
            '@type': 'PostalAddress',
            'streetAddress': AppEnv.street,
            if (AppEnv.city.isNotEmpty) 'addressLocality': AppEnv.city,
            if (AppEnv.state.isNotEmpty) 'addressRegion': AppEnv.state,
            if (AppEnv.zip.isNotEmpty) 'postalCode': AppEnv.zip,
            if (AppEnv.country.isNotEmpty) 'addressCountry': AppEnv.country,
          },
      };
      final jsonLd = {
        '@context': 'https://schema.org',
        '@type': 'Service',
        '@id': '${AppEnv.siteUrl}/services/${service.slug}',
        'name': service.name,
        'description': service.description,
        'url': '${AppEnv.siteUrl}/services/${service.slug}',
        'provider': provider,
        if (AppEnv.city.isNotEmpty) 'areaServed': AppEnv.city,
        'offers': {
          '@type': 'Offer',
          'price': service.price,
          'priceCurrency': 'USD',
        },
      };

      // Meta description: trim to 160 chars
      final rawDesc = service.description;
      final metaDesc = rawDesc.length > 160
          ? '${rawDesc.substring(0, 157)}...'
          : rawDesc;

      // Title: include city for local SEO when available
      final pageTitle = AppEnv.city.isNotEmpty
          ? '${service.name} in ${AppEnv.city} | ${AppEnv.clientName}'
          : '${service.name} | ${AppEnv.clientName}';

      return SeoWrapper(
        title: pageTitle,
        description: metaDesc,
        canonical: '${AppEnv.siteUrl}/services/${service.slug}',
        jsonLd: jsonEncode(jsonLd),
        jsonLdId: 'service-${service.slug}',
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: service.imageUrl != null
                      ? Image.network(service.imageUrl!, fit: BoxFit.cover)
                      : Container(color: EColors.primaryLight),
                ),
              ),
              SliverToBoxAdapter(
                child: SectionWrapper(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name, style: ETextStyles.displayMd),
                      const SizedBox(height: ESpacing.md),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: EColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: ESpacing.xs),
                          Text(
                            service.formattedDuration,
                            style: ETextStyles.bodyLg,
                          ),
                          const SizedBox(width: ESpacing.lg),
                          Icon(
                            Icons.payments_outlined,
                            color: EColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: ESpacing.xs),
                          Text(
                            service.formattedPrice,
                            style: ETextStyles.bodyLg,
                          ),
                        ],
                      ),
                      const Divider(height: ESpacing.xxl),
                      Text('About this service', style: ETextStyles.h2),
                      const SizedBox(height: ESpacing.md),
                      Text(service.description, style: ETextStyles.bodyLg),
                      const SizedBox(height: ESpacing.xxxl),
                      if (AppEnv.moduleEnabled('booking'))
                        Center(
                          child: ElevatedButton(
                            onPressed: () => Get.toNamed(
                              '/booking',
                              arguments: {'serviceId': service.id},
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: ESpacing.xl,
                                vertical: ESpacing.lg,
                              ),
                            ),
                            child: const Text('Book Now'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
