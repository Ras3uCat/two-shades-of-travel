import 'package:get/get.dart';
import '../../../core/theme/e_colors.dart';
import '../models/event_model.dart';
import '../models/event_ticket_model.dart';
import '../models/event_ticket_type_model.dart';
import '../repositories/events_repository.dart';

class EventsAdminController extends GetxController {
  EventsAdminController(this._repo);
  final EventsRepository _repo;

  final events          = <EventModel>[].obs;
  final selectedEventId = RxnString();
  final attendees       = <EventTicketModel>[].obs;
  final ticketTypes     = <EventTicketTypeModel>[].obs;

  final isLoading    = false.obs;
  final isCancelling = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadEvents();
  }

  Future<void> loadEvents() async {
    isLoading.value = true;
    try {
      events.value = await _repo.getAllEvents();
    } catch (_) {
      events.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createEvent(Map<String, dynamic> data) async {
    await _repo.createEvent(data);
    await loadEvents();
  }

  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _repo.updateEvent(id, data);
    await loadEvents();
  }

  Future<void> loadAttendees(String eventId) async {
    selectedEventId.value = eventId;
    isLoading.value       = true;
    try {
      final results = await Future.wait([
        _repo.getAdminTicketTypes(eventId),
        _repo.getAttendees(eventId),
      ]);
      ticketTypes.value = results[0] as List<EventTicketTypeModel>;
      attendees.value   = results[1] as List<EventTicketModel>;
    } catch (_) {
      attendees.value   = [];
      ticketTypes.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkInTicket(String ticketId) async {
    try {
      await _repo.checkInTicket(ticketId);
      final idx = attendees.indexWhere((a) => a.id == ticketId);
      if (idx >= 0) {
        final old = attendees[idx];
        attendees[idx] = EventTicketModel(
          id:           old.id,
          eventId:      old.eventId,
          ticketTypeId: old.ticketTypeId,
          buyerName:    old.buyerName,
          buyerEmail:   old.buyerEmail,
          quantity:     old.quantity,
          totalCents:   old.totalCents,
          ticketCode:   old.ticketCode,
          status:       'checked_in',
          checkedInAt:  DateTime.now(),
          createdAt:    old.createdAt,
        );
        // ignore: invalid_use_of_protected_member
        attendees.refresh();
      }
    } catch (_) {}
  }

  Future<void> cancelEvent(String eventId) async {
    isCancelling.value = true;
    try {
      await _repo.cancelEvent(eventId);
      await loadEvents();
      Get.snackbar(
        'Event cancelled',
        'All tickets have been cancelled and refunds issued.',
        backgroundColor: EColors.error.withValues(alpha: 0.9),
        colorText:       EColors.onSurface,
      );
    } catch (_) {
      Get.snackbar('Error', 'Failed to cancel event. Please try again.');
    } finally {
      isCancelling.value = false;
    }
  }

  Future<void> createTicketType(String eventId, Map<String, dynamic> data) async {
    await _repo.createTicketType(eventId, data);
    await loadAttendees(eventId);
  }

  Future<void> updateTicketType(String id, Map<String, dynamic> data) async {
    await _repo.updateTicketType(id, data);
    final eventId = selectedEventId.value;
    if (eventId != null) await loadAttendees(eventId);
  }

  Future<void> deleteTicketType(String id) async {
    try {
      await _repo.deleteTicketType(id);
      ticketTypes.removeWhere((t) => t.id == id);
    } catch (_) {
      Get.snackbar('Error', 'Cannot delete a ticket type that has confirmed tickets.');
    }
  }

  // ── Computed stats for the attendees view ─────────────────────────────────
  int get totalSold      => attendees.fold(0, (s, a) => s + (a.isPending || a.isConfirmed || a.isCheckedIn ? a.quantity : 0));
  int get totalConfirmed => attendees.fold(0, (s, a) => s + (a.isConfirmed ? a.quantity : 0));
  int get totalCheckedIn => attendees.fold(0, (s, a) => s + (a.isCheckedIn ? a.quantity : 0));
  double get totalRevenue => attendees.fold(0.0, (s, a) => s + (a.isConfirmed || a.isCheckedIn ? a.totalPrice : 0));
}
