import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/app_router.dart';
import '../models/event_model.dart';
import '../models/event_ticket_model.dart';
import '../models/event_ticket_type_model.dart';
import '../repositories/events_repository.dart';

class EventsController extends GetxController {
  EventsController(this._repo);
  final EventsRepository _repo;

  final events       = <EventModel>[].obs;
  final selectedEvent = Rxn<EventModel>();
  final ticketTypes  = <EventTicketTypeModel>[].obs;
  final availability = <String, int>{}.obs;

  final selectedTypeId = RxnString();
  final quantity       = 1.obs;
  final buyerName      = ''.obs;
  final buyerEmail     = ''.obs;

  final isLoading    = false.obs;
  final isPurchasing = false.obs;
  final error        = RxnString();

  @override
  void onInit() {
    super.onInit();
    _handleStripeCancelReturn();
    loadEvents();
  }

  Future<void> loadEvents() async {
    isLoading.value = true;
    try {
      events.value = await _repo.getPublishedEvents();
    } catch (_) {
      events.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadEventDetail(String slug) async {
    isLoading.value = true;
    error.value     = null;
    try {
      final ev = await _repo.getEventBySlug(slug);
      selectedEvent.value = ev;
      final types = await _repo.getTicketTypes(ev.id);
      ticketTypes.value = types;
      if (types.isNotEmpty) selectedTypeId.value = types.first.id;
      final avail = await _repo.getTicketAvailability(ev.id);
      availability.value = avail;
    } catch (e) {
      error.value = 'Failed to load event. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Reload just availability (called after a cancelled-ticket return).
  Future<void> refreshAvailability() async {
    final ev = selectedEvent.value;
    if (ev == null) return;
    final avail = await _repo.getTicketAvailability(ev.id);
    availability.value = avail;
  }

  void selectType(String id) => selectedTypeId.value = id;

  void incrementQty() {
    final max = availability[selectedTypeId.value] ?? 0;
    if (quantity.value < max) quantity.value++;
  }

  void decrementQty() {
    if (quantity.value > 1) quantity.value--;
  }

  EventTicketTypeModel? get selectedType =>
      ticketTypes.firstWhereOrNull((t) => t.id == selectedTypeId.value);

  int get remainingForSelected => availability[selectedTypeId.value] ?? 0;

  Future<void> purchase() async {
    final ev   = selectedEvent.value;
    final type = selectedType;
    if (ev == null || type == null) return;
    if (buyerName.value.trim().isEmpty || buyerEmail.value.trim().isEmpty) {
      error.value = 'Please enter your name and email.';
      return;
    }

    isPurchasing.value = true;
    error.value        = null;

    try {
      final result = await _repo.checkout(
        eventId:       ev.id,
        ticketTypeId:  type.id,
        quantity:      quantity.value,
        buyerEmail:    buyerEmail.value.trim(),
        buyerName:     buyerName.value.trim(),
      );

      if (result['confirmed'] == true) {
        // Free event — confirmed immediately
        final ticketId   = result['ticket_id']   as String;
        final ticketCode = result['ticket_code']  as String;
        final ticket = EventTicketModel(
          id:           ticketId,
          eventId:      ev.id,
          ticketTypeId: type.id,
          buyerName:    buyerName.value.trim(),
          buyerEmail:   buyerEmail.value.trim(),
          quantity:     quantity.value,
          totalCents:   0,
          ticketCode:   ticketCode,
          status:       'confirmed',
          createdAt:    DateTime.now(),
        );
        Get.toNamed(ERoutes.eventsConfirmation, arguments: ticket);
      } else if (result['url'] != null) {
        // Paid event — redirect to Stripe
        await launchUrl(Uri.parse(result['url'] as String), mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      error.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isPurchasing.value = false;
    }
  }

  void _handleStripeCancelReturn() {
    final cancelledId = Get.parameters['cancelled_ticket_id'];
    if (cancelledId == null || cancelledId.isEmpty) return;
    _repo.cancelPendingTicket(cancelledId).catchError((_) {});
    refreshAvailability();
  }
}
