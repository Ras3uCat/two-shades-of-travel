import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_env.dart';
import '../../modules/booking/models/booking_model.dart';

/// IcsService — generates a .ics calendar file and triggers a download/open.
/// Uses a data: URI so no server round-trip is needed.
/// On iOS this opens the Calendar app; on Android it opens compatible apps;
/// on web it triggers a browser download dialog.
class IcsService {
  IcsService._();

  static Future<void> addToCalendar(BookingModel booking) async {
    final ics = _buildIcs(booking);
    final encoded = Uri.encodeComponent(ics);
    final uri = Uri.parse('data:text/calendar;charset=utf8,$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static String _buildIcs(BookingModel booking) {
    final now     = DateTime.now().toUtc();
    final start   = booking.startTime.toUtc();
    final end     = booking.endTime.toUtc();
    final uid     = '${booking.id}@${AppEnv.clientSlug}';
    final summary = '${booking.serviceNames.join(', ')} with ${booking.artistName}';

    final lines = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Raspucat//ClientApp//EN',
      'BEGIN:VEVENT',
      'UID:$uid',
      'DTSTAMP:${_fmt(now)}',
      'DTSTART:${_fmt(start)}',
      'DTEND:${_fmt(end)}',
      'SUMMARY:$summary',
      'LOCATION:${AppEnv.clientName}',
      if (booking.clientNotes != null && booking.clientNotes!.isNotEmpty)
        'DESCRIPTION:${booking.clientNotes}',
      'END:VEVENT',
      'END:VCALENDAR',
    ];

    return lines.join('\r\n');
  }

  static String _fmt(DateTime dt) {
    final y  = dt.year.toString().padLeft(4, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final d  = dt.day.toString().padLeft(2, '0');
    final h  = dt.hour.toString().padLeft(2, '0');
    final m  = dt.minute.toString().padLeft(2, '0');
    final s  = dt.second.toString().padLeft(2, '0');
    return '$y$mo${d}T$h$m${s}Z';
  }
}
