import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/events_controller.dart';

class EventDetailView extends GetView<EventsController> {
  const EventDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final slug = Get.parameters['slug'] ?? '';
    if (slug.isNotEmpty && controller.selectedEvent.value?.slug != slug) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadEventDetail(slug);
      });
    }

    return Scaffold(
      backgroundColor: EColors.surface,
      body: Obx(() {
        if (controller.isLoading.value && controller.selectedEvent.value == null) {
          return Center(child: CircularProgressIndicator(color: EColors.primary));
        }
        final event = controller.selectedEvent.value;
        if (event == null) {
          return Center(child: Text('Event not found.', style: ETextStyles.bodyMuted));
        }

        return CustomScrollView(
          slivers: [
            _HeroSliver(
              title:        event.title,
              imageUrl:     event.heroImageUrl,
              isCancelled:  event.isCancelled,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(ESpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(Icons.calendar_today_outlined, event.formattedDate),
                    if (event.venue != null)
                      _InfoRow(Icons.place_outlined, event.venue!),
                    const SizedBox(height: ESpacing.lg),
                    if (event.description != null) ...[
                      Text(event.description!, style: ETextStyles.body),
                      const SizedBox(height: ESpacing.xl),
                    ],
                    if (!event.isCancelled) ...[
                      Text('Get Tickets', style: ETextStyles.h3),
                      const SizedBox(height: ESpacing.md),
                      _TicketSelector(controller: controller),
                      const SizedBox(height: ESpacing.md),
                      _BuyerForm(controller: controller),
                      const SizedBox(height: ESpacing.lg),
                      Obx(() {
                        if (controller.error.value != null) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: ESpacing.md),
                            child: Text(controller.error.value!,
                                style: ETextStyles.bodySm.copyWith(
                                    color: EColors.error)),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      _PurchaseButton(controller: controller),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(ESpacing.md),
                        color: EColors.error.withValues(alpha: 0.1),
                        child: Text('This event has been cancelled.',
                            style: ETextStyles.body.copyWith(color: EColors.error)),
                      ),
                    const SizedBox(height: ESpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _HeroSliver extends StatelessWidget {
  const _HeroSliver({
    required this.title,
    required this.imageUrl,
    required this.isCancelled,
  });
  final String  title;
  final String? imageUrl;
  final bool    isCancelled;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: imageUrl != null ? 240 : 120,
      pinned: true,
      backgroundColor: EColors.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: imageUrl != null
            ? Image.network(imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: EColors.divider))
            : Container(color: EColors.surfaceVariant),
        title: Text(title,
            style: ETextStyles.h4.copyWith(color: EColors.onSurface),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        titlePadding:
            const EdgeInsets.symmetric(horizontal: ESpacing.md, vertical: ESpacing.sm),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String   text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ESpacing.xs),
      child: Row(children: [
        Icon(icon, size: 16, color: EColors.primary),
        const SizedBox(width: ESpacing.xs),
        Expanded(child: Text(text, style: ETextStyles.bodySm)),
      ]),
    );
  }
}

class _TicketSelector extends StatelessWidget {
  const _TicketSelector({required this.controller});
  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.ticketTypes.isEmpty) {
        return Text('No tickets available.', style: ETextStyles.bodyMuted);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: InputDecoration(
              labelText:  'Ticket type',
              labelStyle: ETextStyles.inputLabel,
            ),
            child: DropdownButton<String>(
              value:         controller.selectedTypeId.value,
              isExpanded:    true,
              underline:     const SizedBox.shrink(),
              dropdownColor: EColors.surfaceVariant,
              style:         ETextStyles.inputText,
              items: controller.ticketTypes.map((t) {
                final remaining = controller.availability[t.id] ?? 0;
                final soldOut   = remaining == 0;
                return DropdownMenuItem(
                  value:   t.id,
                  enabled: !soldOut,
                  child:   Text(
                    '${t.name} — ${t.formattedPrice}'
                    '${soldOut ? ' (Sold out)' : ' ($remaining left)'}',
                    style: ETextStyles.body.copyWith(
                        color: soldOut ? EColors.onSurfaceMuted : EColors.onSurface),
                  ),
                );
              }).toList(),
              onChanged: (id) { if (id != null) controller.selectType(id); },
            ),
          ),
          const SizedBox(height: ESpacing.md),
          Row(children: [
            Text('Quantity:', style: ETextStyles.label),
            const SizedBox(width: ESpacing.md),
            IconButton(
              onPressed: controller.decrementQty,
              icon: Icon(Icons.remove, color: EColors.primary),
            ),
            Obx(() => Text('${controller.quantity}', style: ETextStyles.h4)),
            IconButton(
              onPressed: controller.incrementQty,
              icon: Icon(Icons.add, color: EColors.primary),
            ),
          ]),
        ],
      );
    });
  }
}

class _BuyerForm extends StatelessWidget {
  const _BuyerForm({required this.controller});
  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TextField(
        decoration: InputDecoration(
          labelText:  'Your name',
          labelStyle: ETextStyles.inputLabel,
        ),
        style:   ETextStyles.inputText,
        onChanged: (v) => controller.buyerName.value = v,
      ),
      const SizedBox(height: ESpacing.md),
      TextField(
        decoration: InputDecoration(
          labelText:  'Email address',
          labelStyle: ETextStyles.inputLabel,
        ),
        style:         ETextStyles.inputText,
        keyboardType:  TextInputType.emailAddress,
        onChanged:     (v) => controller.buyerEmail.value = v,
      ),
    ]);
  }
}

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({required this.controller});
  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final type    = controller.selectedType;
      final loading = controller.isPurchasing.value;
      final label   = type?.isFree == true ? 'REGISTER FREE' : 'BUY TICKETS';

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: loading ? null : controller.purchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: EColors.primary,
            foregroundColor: EColors.secondary,
            padding:         const EdgeInsets.symmetric(vertical: ESpacing.md),
            shape:           const RoundedRectangleBorder(),
          ),
          child: loading
              ? SizedBox(
                  height: 20,
                  width:  20,
                  child:  CircularProgressIndicator(
                      strokeWidth: 2, color: EColors.secondary))
              : Text(label, style: ETextStyles.button),
        ),
      );
    });
  }
}
