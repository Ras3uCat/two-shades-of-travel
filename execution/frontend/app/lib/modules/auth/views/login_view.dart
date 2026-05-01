import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../../../core/config/app_env.dart';
import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final emailCtrl    = TextEditingController();
    final passwordCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: EColors.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(ESpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppEnv.clientName, style: ETextStyles.h2, textAlign: TextAlign.center),
                const SizedBox(height: ESpacing.xs),
                Text('Team Login', style: ETextStyles.bodyMuted, textAlign: TextAlign.center),
                const SizedBox(height: ESpacing.xxl),

                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: ESpacing.md),

                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: ESpacing.xs),

                Obx(() {
                  if (controller.error.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: ESpacing.xs),
                    child: Text(
                      controller.error,
                      style: ETextStyles.bodySm.copyWith(color: EColors.error),
                    ),
                  );
                }),

                const SizedBox(height: ESpacing.lg),

                Obx(() => ElevatedButton(
                  onPressed: controller.isLoading
                      ? null
                      : () => controller.signIn(emailCtrl.text, passwordCtrl.text),
                  child: controller.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                )),

                if (AppEnv.googleAuthEnabled || AppEnv.appleAuthEnabled) ...[
                  const SizedBox(height: ESpacing.lg),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: ESpacing.md),
                      child: Text('or', style: ETextStyles.bodySm.copyWith(
                          color: EColors.onSurfaceMuted)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: ESpacing.lg),
                  if (AppEnv.googleAuthEnabled)
                    OutlinedButton.icon(
                      onPressed: controller.signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 20),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EColors.onSurface,
                        side: BorderSide(color: EColors.divider),
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                  if (AppEnv.googleAuthEnabled && AppEnv.appleAuthEnabled)
                    const SizedBox(height: ESpacing.sm),
                  if (AppEnv.appleAuthEnabled)
                    OutlinedButton.icon(
                      onPressed: controller.signInWithApple,
                      icon: const Icon(Icons.apple, size: 20),
                      label: const Text('Continue with Apple'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EColors.onSurface,
                        side: BorderSide(color: EColors.divider),
                        shape: const RoundedRectangleBorder(),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
