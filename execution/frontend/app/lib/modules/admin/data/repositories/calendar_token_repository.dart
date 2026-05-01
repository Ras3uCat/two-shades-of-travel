import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CalendarTokenRepository {
  /// Returns the current feed token for [staffId], or null if none exists yet.
  Future<String?> getToken(String staffId);

  /// Upserts a token row for [staffId] (no-op if one exists) and returns token.
  Future<String> ensureToken(String staffId);

  /// Calls the `regenerate_calendar_token` DB function server-side and
  /// returns the new UUID. Old feed URLs break intentionally.
  Future<String> regenerateToken(String staffId);
}

class SupabaseCalendarTokenRepository implements CalendarTokenRepository {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<String?> getToken(String staffId) async {
    final row = await _db
        .from('calendar_tokens')
        .select('token')
        .eq('staff_id', staffId)
        .maybeSingle();
    return row?['token'] as String?;
  }

  @override
  Future<String> ensureToken(String staffId) async {
    // Upsert (ignore if row already exists) then re-read the current token.
    await _db.from('calendar_tokens').upsert(
      {'staff_id': staffId},
      onConflict: 'staff_id',
      ignoreDuplicates: true,
    );
    final row = await _db
        .from('calendar_tokens')
        .select('token')
        .eq('staff_id', staffId)
        .single();
    return row['token'] as String;
  }

  @override
  Future<String> regenerateToken(String staffId) async {
    final result = await _db.rpc(
      'regenerate_calendar_token',
      params: {'p_staff_id': staffId},
    );
    return result as String;
  }
}
