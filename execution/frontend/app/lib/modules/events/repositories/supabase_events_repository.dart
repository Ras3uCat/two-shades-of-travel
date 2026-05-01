import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../models/event_ticket_model.dart';
import '../models/event_ticket_type_model.dart';
import 'events_repository.dart';

class SupabaseEventsRepository implements EventsRepository {
  SupabaseClient get _db => Supabase.instance.client;

  // ── Public ────────────────────────────────────────────────────────────────

  @override
  Future<List<EventModel>> getPublishedEvents() async {
    final rows = await _db
        .from('events')
        .select()
        .eq('status', 'published')
        .order('event_date');
    return (rows as List).map((r) => EventModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<EventModel> getEventBySlug(String slug) async {
    final row = await _db
        .from('events')
        .select()
        .eq('slug', slug)
        .single();
    return EventModel.fromJson(row);
  }

  @override
  Future<List<EventTicketTypeModel>> getTicketTypes(String eventId) async {
    final rows = await _db
        .from('event_ticket_types')
        .select()
        .eq('event_id', eventId)
        .order('price_cents');
    return (rows as List)
        .map((r) => EventTicketTypeModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, int>> getTicketAvailability(String eventId) async {
    final rows = await _db.rpc('get_ticket_availability', params: {'p_event_id': eventId});
    final map = <String, int>{};
    for (final r in (rows as List)) {
      map[r['ticket_type_id'] as String] = (r['quantity_avail'] as num).toInt();
    }
    return map;
  }

  @override
  Future<Map<String, dynamic>> checkout({
    required String eventId,
    required String ticketTypeId,
    required int    quantity,
    required String buyerEmail,
    required String buyerName,
  }) async {
    final res = await _db.functions.invoke(
      'create-event-checkout',
      body: {
        'event_id':       eventId,
        'ticket_type_id': ticketTypeId,
        'quantity':       quantity,
        'buyer_email':    buyerEmail,
        'buyer_name':     buyerName,
      },
    );
    if (res.status != 200) {
      final err = (res.data as Map?)?['error'] ?? 'Checkout failed';
      throw Exception(err);
    }
    return res.data as Map<String, dynamic>;
  }

  @override
  Future<EventTicketModel?> getTicket(String ticketId) async {
    try {
      // Ticket is fetched with service role from admin — public clients
      // receive ticket data via Get.arguments after in-app purchase.
      // This path is only used on the post-Stripe confirmation screen.
      final row = await _db
          .from('event_tickets')
          .select()
          .eq('id', ticketId)
          .single();
      return EventTicketModel.fromJson(row);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cancelPendingTicket(String ticketId) async {
    await _db
        .from('event_tickets')
        .update({'status': 'cancelled'})
        .eq('id', ticketId)
        .eq('status', 'pending'); // only cancel if still pending — safe guard
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  @override
  Future<List<EventModel>> getAllEvents() async {
    final rows = await _db
        .from('events')
        .select()
        .order('event_date', ascending: false);
    return (rows as List).map((r) => EventModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> createEvent(Map<String, dynamic> data) async {
    await _db.from('events').insert(data);
  }

  @override
  Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _db.from('events').update(data).eq('id', id);
  }

  @override
  Future<List<EventTicketTypeModel>> getAdminTicketTypes(String eventId) async {
    final rows = await _db
        .from('event_ticket_types')
        .select()
        .eq('event_id', eventId)
        .order('price_cents');
    return (rows as List)
        .map((r) => EventTicketTypeModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createTicketType(String eventId, Map<String, dynamic> data) async {
    await _db.from('event_ticket_types').insert({...data, 'event_id': eventId});
  }

  @override
  Future<void> updateTicketType(String id, Map<String, dynamic> data) async {
    await _db.from('event_ticket_types').update(data).eq('id', id);
  }

  @override
  Future<void> deleteTicketType(String id) async {
    await _db.from('event_ticket_types').delete().eq('id', id);
  }

  @override
  Future<List<EventTicketModel>> getAttendees(String eventId) async {
    final rows = await _db
        .from('event_tickets')
        .select()
        .eq('event_id', eventId)
        .order('created_at');
    return (rows as List)
        .map((r) => EventTicketModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> checkInTicket(String ticketId) async {
    await _db.from('event_tickets').update({
      'status':        'checked_in',
      'checked_in_at': DateTime.now().toIso8601String(),
    }).eq('id', ticketId);
  }

  @override
  Future<void> cancelEvent(String eventId) async {
    await _db.functions.invoke('cancel-event', body: {'event_id': eventId});
  }
}
