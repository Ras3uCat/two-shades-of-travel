import 'package:flutter/material.dart';
import '../../../core/config/app_env.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/seo_wrapper.dart';
import '../widgets/testimonials_section.dart';

class TestimonialsView extends StatelessWidget {
  const TestimonialsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SeoWrapper(
      title: 'Reviews',
      description: 'See what clients say about ${AppEnv.clientName}.',
      child: AppShell(
        child: SingleChildScrollView(
          child: const TestimonialsSection(),
        ),
      ),
    );
  }
}
