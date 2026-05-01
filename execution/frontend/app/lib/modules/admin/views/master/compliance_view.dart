import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/e_colors.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../../controllers/master_controller.dart';
import '../admin_shell.dart';

/// ComplianceView — GDPR Right-to-be-Forgotten.
/// Master admin enters an email to hard-delete all associated data.
class ComplianceView extends StatefulWidget {
  const ComplianceView({super.key});

  @override
  State<ComplianceView> createState() => _ComplianceViewState();
}

class _ComplianceViewState extends State<ComplianceView> {
  final _ctrl       = Get.find<MasterController>();
  final _emailCtrl  = TextEditingController();
  final _formKey    = GlobalKey<FormState>();

  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailCtrl.text.trim();
    final confirmed = await _showConfirmDialog(email);
    if (!confirmed) return;

    setState(() { _loading = true; _result = null; _error = null; });
    try {
      final summary = await _ctrl.forgetUser(email);
      setState(() { _result = summary; });
      _emailCtrl.clear();
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<bool> _showConfirmDialog(String email) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permanent deletion'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All data for the following email will be permanently deleted:',
                  style: ETextStyles.body,
                ),
                const SizedBox(height: ESpacing.sm),
                Text(email, style: ETextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: ESpacing.md),
                Text(
                  'This includes bookings, newsletter subscriptions, loyalty points, '
                  'referrals, and the user account. This action cannot be undone.',
                  style: ETextStyles.bodySm.copyWith(color: EColors.onSurfaceMuted),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete all data'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentRoute: ERoutes.adminCompliance,
      isMaster: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ESpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data Deletion', style: ETextStyles.h2),
              const SizedBox(height: ESpacing.xs),
              Text(
                'Permanently delete all data associated with a user email. '
                'Use this to comply with GDPR right-to-be-forgotten requests.',
                style: ETextStyles.body.copyWith(color: EColors.onSurfaceMuted),
              ),
              const SizedBox(height: ESpacing.xl),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: ETextStyles.inputText,
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        hintText: 'user@example.com',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: ESpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Delete all data for this email'),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: ESpacing.lg),
                _StatusCard(isError: true, child: Text(_error!, style: ETextStyles.bodySm)),
              ],
              if (_result != null) ...[
                const SizedBox(height: ESpacing.lg),
                _DeletionSummary(result: _result!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeletionSummary extends StatelessWidget {
  const _DeletionSummary({required this.result});
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    return _StatusCard(
      isError: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deletion complete', style: ETextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: ESpacing.sm),
          _Row('Bookings deleted',     '${result['bookings'] ?? 0}'),
          _Row('Newsletter entries',   '${result['newsletter'] ?? 0}'),
          _Row('Loyalty points',       '${result['loyalty'] ?? 0}'),
          _Row('Referrals',            '${result['referrals'] ?? 0}'),
          _Row('Auth account removed', result['auth_user'] == true ? 'Yes' : 'No'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: ESpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ETextStyles.bodySm),
          Text(value,  style: ETextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isError, required this.child});
  final bool isError;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.green.shade50,
        border: Border.all(
          color: isError ? Colors.red.shade200 : Colors.green.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
