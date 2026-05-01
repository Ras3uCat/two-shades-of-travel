import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_env.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/seo_wrapper.dart';
import '../../menu/menu_section.dart';
import '../../testimonials/widgets/testimonials_section.dart';
import 'hero/hero_fullbleed.dart';
import 'sections/services_section.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return SeoWrapper(
      title: AppEnv.clientName,
      description: 'Welcome to ${AppEnv.clientName}.',
      child: AppShell(
        child: Column(
          children: [
            _buildHero(),
            ..._buildSections(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return switch (AppEnv.heroVariant) {
      'split'    => const HeroSplit(),
      'centered' => const HeroCentered(),
      _          => const HeroFullbleed(),
    };
  }

  List<Widget> _buildSections() {
    return AppEnv.homeSectionList
        .where((s) => s != 'hero')
        .map(_sectionForId)
        .whereType<Widget>()
        .toList();
  }

  Widget? _sectionForId(String id) {
    return switch (id) {
      'services'     => const ServicesSection(),
      'team'         => const TeamSection(),
      'testimonials' => AppEnv.moduleEnabled('testimonials')
          ? const TestimonialsSection()
          : null,
      'cta'          => const CtaSection(),
      'menu'         => AppEnv.moduleEnabled('menu') ? const MenuSection() : null,
      _              => null,
    };
  }

  Widget _buildFooter() {
    final socials = <String, String>{
      'IG': AppEnv.instagramUrl,
      'FB': AppEnv.facebookUrl,
      'TT': AppEnv.tiktokUrl,
      'YT': AppEnv.youtubeUrl,
    }.entries.where((e) => e.value.isNotEmpty).toList();

    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 80),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '© ${DateTime.now().year} ${AppEnv.clientName}',
            style: ETextStyles.caption.copyWith(color: Colors.white54),
          ),
          if (socials.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: socials.map((e) => TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(e.value),
                  mode: LaunchMode.externalApplication,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white38,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(e.key, style: ETextStyles.caption),
              )).toList(),
            ),
          Text(
            'Powered by Raspucat',
            style: ETextStyles.caption.copyWith(color: Colors.white24),
          ),
        ],
      ),
    );
  }
}
