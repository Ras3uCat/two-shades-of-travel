import 'package:intl/intl.dart';

class TimeSlotModel {
  final String id;
  final String artistId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isBooked;         // blocked for any reason
  final bool isDirectBooked;   // an actual booking starts at this exact time

  const TimeSlotModel({
    required this.id,
    required this.artistId,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.isDirectBooked = false,
  });

  int get durationMinutes =>
      endTime.difference(startTime).inMinutes;

  String get formattedTime =>
      DateFormat('h:mm a').format(startTime);

  String get formattedEndTime =>
      DateFormat('h:mm a').format(endTime);

  String get formattedDate =>
      DateFormat('EEE, MMM d').format(startTime);

  String get dayShort =>
      DateFormat('EEE').format(startTime).toUpperCase();

  String get dayNum =>
      startTime.day.toString();

  factory TimeSlotModel.fromMap(Map<String, dynamic> map) {
    return TimeSlotModel(
      id:            map['id'] as String,
      artistId:      map['artist_id'] as String,
      startTime:     DateTime.parse(map['start_time'] as String).toLocal(),
      endTime:       DateTime.parse(map['end_time'] as String).toLocal(),
      isBooked:      map['is_booked'] as bool? ?? false,
      isDirectBooked: map['is_direct_booked'] as bool? ?? false,
    );
  }
}
