import '../models/event_model.dart';
import '../models/event_ticket_model.dart';
import '../models/event_ticket_type_model.dart';

abstract class EventsRepository {
  // ── Public ────────────────────────────────────────────────────────────────
  Future<List<EventModel>> getPublishedEvents();
  Future<EventModel> getEventBySlug(String slug);
  Future<List<EventTicketTypeModel>> getTicketTypes(String eventId);

  /// Returns a map of ticketTypeId → quantity remaining.
  Future<Map<String, int>> getTicketAvailability(String eventId);

  /// For free events returns { confirmed, ticket_id, ticket_code }.
  /// For paid events returns { url } for Stripe Checkout redirect.
  Future<Map<String, dynamic>> checkout({
    required String eventId,
    required String ticketTypeId,
    required int    quantity,
    required String buyerEmail,
    required String buyerName,
  });

  Future<EventTicketModel?> getTicket(String ticketId);
  Future<void> cancelPendingTicket(String ticketId);

  // ── Admin ─────────────────────────────────────────────────────────────────
  Future<List<EventModel>> getAllEvents();
  Future<void> createEvent(Map<String, dynamic> data);
  Future<void> updateEvent(String id, Map<String, dynamic> data);
  Future<List<EventTicketTypeModel>> getAdminTicketTypes(String eventId);
  Future<void> createTicketType(String eventId, Map<String, dynamic> data);
  Future<void> updateTicketType(String id, Map<String, dynamic> data);
  Future<void> deleteTicketType(String id);
  Future<List<EventTicketModel>> getAttendees(String eventId);
  Future<void> checkInTicket(String ticketId);
  Future<void> cancelEvent(String eventId);
}
