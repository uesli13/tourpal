import 'package:equatable/equatable.dart';

class AvailableTime extends Equatable {
  final int dayOfWeek; // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
  final String startTime; // start time in HH:mm format
  final String endTime; // end time in HH:mm format

  const AvailableTime({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  factory AvailableTime.fromMap(Map<String, dynamic> map) {
    return AvailableTime(
      dayOfWeek: map['dayOfWeek'] ?? 0,
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  AvailableTime copyWith({
    int? dayOfWeek,
    String? startTime,
    String? endTime,
  }) {
    return AvailableTime(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object> get props => [dayOfWeek, startTime, endTime];
}