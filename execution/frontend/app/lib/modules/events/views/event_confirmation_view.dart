import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../models/event_ticket_model.dart';

/// Shown after successful ticket purchase.
///
/// Two entry paths:
/// 1. Free event / in-app: [EventTicketModel] passed via Get.arguments.
/// 2. Post-Stripe redirect: `?ticket_id=<id>&paid=1` — shows a generic "check your email" card.
class EventConfirmationView extends StatelessWidget {
  const EventConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    final ticket = Get.arguments as EventTicketModel?;
    final isPaid = Get.parameters['paid'] == '1';

    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        title: Text('Booking Confirmed', style: ETextStyles.h3),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(ESpacing.lg),
            child: ticket != null
                ? _InAppCard(ticket: ticket)
                : _PostStripeCard(isPaid: isPaid),
          ),
        ),
      ),
    );
  }
}

class _InAppCard extends StatelessWidget {
  const _InAppCard({required this.ticket});
  final EventTicketModel ticket;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 64, color: EColors.primary),
        const SizedBox(height: ESpacing.lg),
        Text("You're in!", style: ETextStyles.h2),
        const SizedBox(height: ESpacing.sm),
        Text(
          'Your ticket has been confirmed. Show this code at the door.',
          style:     ETextStyles.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ESpacing.xl),
        _CodeBox(code: ticket.codeDisplay),
        const SizedBox(height: ESpacing.sm),
        Text(
          'A confirmation email has been sent to ${ticket.buyerEmail}.',
          style:     ETextStyles.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ESpacing.xl),
        _HomeButton(),
      ],
    );
  }
}

class _PostStripeCard extends StatelessWidget {
  const _PostStripeCard({required this.isPaid});
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 64, color: EColors.primary),
        const SizedBox(height: ESpacing.lg),
        Text('Payment confirmed!', style: ETextStyles.h2),
        const SizedBox(height: ESpacing.sm),
        Text(
          'Check your email for your ticket code and event details.',
          style:     ETextStyles.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: ESpacing.xl),
        _HomeButton(),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ESpacing.xl, vertical: ESpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: EColors.primary, width: 2),
        color:  EColors.primaryLight,
      ),
      child: Text(
        code,
        style: ETextStyles.h1.copyWith(
            letterSpacing: 8, color: EColors.primary),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Get.offAllNamed(ERoutes.home),
        style: ElevatedButton.styleFrom(
          backgroundColor: EColors.primary,
          foregroundColor: EColors.secondary,
          padding:         const EdgeInsets.symmetric(vertical: ESpacing.md),
          shape:           const RoundedRectangleBorder(),
        ),
        child: Text('BACK TO HOME', style: ETextStyles.button),
      ),
    );
  }
}
