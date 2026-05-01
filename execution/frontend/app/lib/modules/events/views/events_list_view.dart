import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';
import '../controllers/events_controller.dart';
import '../models/event_model.dart';
import '../models/event_ticket_type_model.dart';
import '../repositories/events_repository.dart';

class EventsListView extends GetView<EventsController> {
  const EventsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EColors.surface,
      appBar: AppBar(
        backgroundColor: EColors.surface,
        title: Text('Events', style: ETextStyles.h3),
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: EColors.primary));
        }
        if (controller.events.isEmpty) {
          return Center(
            child: Text('No upcoming events.', style: ETextStyles.bodyMuted),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(ESpacing.md),
          itemCount: controller.events.length,
          separatorBuilder: (_, _) => const SizedBox(height: ESpacing.md),
          itemBuilder: (_, i) {
            final event = controller.events[i];
            return _EventCard(
              event: event,
              onTap: () => Get.toNamed(
                ERoutes.eventsDetail.replaceFirst(':slug', event.slug),
              ),
            );
          },
        );
      }),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});
  final EventModel   event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:  EColors.surfaceVariant,
          border: Border.all(color: EColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.heroImageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 7,
                child: Image.network(
                  event.heroImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: EColors.divider),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(ESpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: ETextStyles.h4),
                  const SizedBox(height: ESpacing.xxs),
                  Text(event.formattedDate, style: ETextStyles.caption),
                  if (event.venue != null) ...[
                    const SizedBox(height: ESpacing.xxs),
                    Text(event.venue!, style: ETextStyles.caption),
                  ],
                  const SizedBox(height: ESpacing.sm),
                  _TicketPriceLabel(eventId: event.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loads ticket types + availability for the card and shows cheapest price or "Sold Out".
class _TicketPriceLabel extends StatefulWidget {
  const _TicketPriceLabel({required this.eventId});
  final String eventId;

  @override
  State<_TicketPriceLabel> createState() => _TicketPriceLabelState();
}

class _TicketPriceLabelState extends State<_TicketPriceLabel> {
  List<EventTicketTypeModel> _types = [];
  Map<String, int>           _avail = {};
  bool                       _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo  = Get.find<EventsRepository>();
      final types = await repo.getTicketTypes(widget.eventId);
      final avail = await repo.getTicketAvailability(widget.eventId);
      if (mounted) setState(() { _types = types; _avail = avail; _loaded = true; });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final allSoldOut = _types.isNotEmpty &&
        _types.every((t) => (_avail[t.id] ?? 0) == 0);

    if (allSoldOut) {
      return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: ESpacing.sm, vertical: ESpacing.xxs),
        color: EColors.error.withValues(alpha: 0.15),
        child: Text('SOLD OUT',
            style: ETextStyles.labelSm.copyWith(color: EColors.error)),
      );
    }

    final cheapest = _types
        .where((t) => (_avail[t.id] ?? 0) > 0)
        .fold<EventTicketTypeModel?>(
            null,
            (min, t) =>
                min == null || t.priceCents < min.priceCents ? t : min);

    if (cheapest == null) return const SizedBox.shrink();

    return Text(
      'From ${cheapest.formattedPrice}',
      style: ETextStyles.label.copyWith(color: EColors.primary),
    );
  }
}
