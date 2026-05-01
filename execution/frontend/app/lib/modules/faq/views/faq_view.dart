import 'package:flutter/material.dart';
import '../../../core/config/app_env.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/seo_wrapper.dart';
import '../widgets/faq_section.dart';

class FaqView extends StatelessWidget {
  const FaqView({super.key});

  @override
  Widget build(BuildContext context) {
    return SeoWrapper(
      title: 'FAQ',
      description:
          'Answers to frequently asked questions about ${AppEnv.clientName}.',
      child: AppShell(
        child: SingleChildScrollView(
          child: const FaqSection(),
        ),
      ),
    );
  }
}
