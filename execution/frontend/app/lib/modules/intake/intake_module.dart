import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../modules/_registry/module_registry.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/e_colors.dart';
import '../../core/theme/e_spacing.dart';
import '../../core/theme/e_text_styles.dart';

class IntakeModule implements AppModule {
  @override
  String get moduleId => 'intake';
  @override
  NavItem? get navItem => null;
  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.intake,
          page: () => const IntakeFormView(),
          binding: IntakeBinding(),
          transition: Transition.fadeIn,
        ),
      ];
  @override
  Bindings? get binding => null;
}

class IntakeBinding extends Bindings {
  @override
  void dependencies() { Get.put(IntakeController()); }
}

class IntakeController extends GetxController {
  final bookingId    = ''.obs;
  final questions    = <Map<String, dynamic>>[].obs;
  final answers      = <String, dynamic>{}.obs;
  final isLoading    = false.obs;
  final isSubmitting = false.obs;
  final submitted    = false.obs;
  final error        = RxnString();

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    bookingId.value = Get.parameters['booking_id'] ?? '';
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    isLoading.value = true;
    error.value = null;
    try {
      final rows = await _db
          .from('intake_questions')
          .select()
          .eq('is_active', true)
          .order('display_order');
      questions.value = List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      error.value = 'Failed to load questions.';
    } finally {
      isLoading.value = false;
    }
  }

  void setAnswer(String questionId, dynamic value) {
    answers[questionId] = value;
    answers.refresh();
  }

  Future<void> submit() async {
    isSubmitting.value = true;
    error.value = null;
    try {
      await _db.from('intake_responses').insert({
        'booking_id': bookingId.value,
        'answers':    Map<String, dynamic>.from(answers),
      });
      submitted.value = true;
    } catch (_) {
      error.value = 'Could not submit. Please try again.';
    } finally {
      isSubmitting.value = false;
    }
  }
}

class IntakeFormView extends GetView<IntakeController> {
  const IntakeFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        title: Text('Pre-appointment Form', style: ETextStyles.h3),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.submitted.value) return _SubmittedView();
        if (controller.questions.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('No questions available.', style: ETextStyles.bodyMuted),
              const SizedBox(height: ESpacing.lg),
              TextButton(
                onPressed: () => Get.offAllNamed(ERoutes.home),
                child: Text('Continue',
                    style: ETextStyles.button.copyWith(color: EColors.primary)),
              ),
            ]),
          );
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(ESpacing.xl),
              children: [
                Text('A few quick questions before your appointment.',
                    style: ETextStyles.bodyMuted),
                const SizedBox(height: ESpacing.xl),
                ...controller.questions.map((q) => _QuestionItem(question: q)),
                if (controller.error.value != null) ...[
                  const SizedBox(height: ESpacing.md),
                  Text(controller.error.value!,
                      style: ETextStyles.bodySm.copyWith(color: EColors.error)),
                ],
                const SizedBox(height: ESpacing.xl),
                Row(children: [
                  TextButton(
                    onPressed: () => Get.offAllNamed(ERoutes.home),
                    child: Text('Skip',
                        style: ETextStyles.button
                            .copyWith(color: EColors.onSurfaceMuted)),
                  ),
                  const Spacer(),
                  Obx(() => ElevatedButton(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : controller.submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EColors.primary,
                          foregroundColor: EColors.secondary,
                          shape: const RoundedRectangleBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: ESpacing.xl, vertical: ESpacing.md),
                        ),
                        child: controller.isSubmitting.value
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text('Submit', style: ETextStyles.button),
                      )),
                ]),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _QuestionItem extends GetView<IntakeController> {
  const _QuestionItem({required this.question});
  final Map<String, dynamic> question;

  @override
  Widget build(BuildContext context) {
    final id        = question['id'] as String;
    final label     = question['label'] as String? ?? '';
    final fieldType = question['field_type'] as String? ?? 'text';
    final required  = question['is_required'] as bool? ?? false;
    final options   = (question['options'] as List?)
            ?.map((e) => e.toString()).toList() ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: ESpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: ETextStyles.label)),
          if (required)
            Text(' *',
                style: ETextStyles.labelSm.copyWith(color: EColors.error)),
        ]),
        const SizedBox(height: ESpacing.sm),
        if (fieldType == 'yesno')
          Obx(() {
            final cur = controller.answers[id];
            return Row(children: [
              _ToggleBtn(label: 'Yes', selected: cur == true,
                  onTap: () => controller.setAnswer(id, true)),
              const SizedBox(width: ESpacing.sm),
              _ToggleBtn(label: 'No', selected: cur == false,
                  onTap: () => controller.setAnswer(id, false)),
            ]);
          })
        else if (fieldType == 'select')
          Obx(() {
            final cur = controller.answers[id] as String?;
            return DropdownButton<String>(
              value: options.contains(cur) ? cur : null,
              hint: Text('Select an option', style: ETextStyles.bodySmMuted),
              isExpanded: true,
              underline: Container(height: 1, color: EColors.divider),
              style: ETextStyles.inputText,
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) { if (v != null) controller.setAnswer(id, v); },
            );
          })
        else
          TextField(
            maxLines: fieldType == 'textarea' ? 4 : 1,
            style: ETextStyles.inputText,
            decoration: InputDecoration(
              hintText: 'Your answer...',
              hintStyle: ETextStyles.bodySmMuted,
            ),
            onChanged: (v) => controller.setAnswer(id, v),
          ),
      ]),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: ESpacing.lg, vertical: ESpacing.sm),
        decoration: BoxDecoration(
          color: selected ? EColors.primary : EColors.surfaceVariant,
          border: Border.all(
              color: selected ? EColors.primary : EColors.divider, width: 0.5),
        ),
        child: Text(label,
            style: ETextStyles.label.copyWith(
                color: selected ? EColors.secondary : EColors.onSurface)),
      ),
    );
  }
}

class _SubmittedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ESpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, size: 64, color: EColors.primary),
          const SizedBox(height: ESpacing.lg),
          Text('All done!', style: ETextStyles.h2),
          const SizedBox(height: ESpacing.sm),
          Text(
            'Your responses have been saved. See you at your appointment.',
            style: ETextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ESpacing.xl),
          ElevatedButton(
            onPressed: () => Get.offAllNamed(ERoutes.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: EColors.primary,
              foregroundColor: EColors.secondary,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(
                  horizontal: ESpacing.xl, vertical: ESpacing.md),
            ),
            child: Text('Back to home', style: ETextStyles.button),
          ),
        ]),
      ),
    );
  }
}
