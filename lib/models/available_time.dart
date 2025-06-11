class AvailableTime {
  final int dayOfWeek;    // 0=Sunday, 1=Monday, ..., 6=Saturday (as per DATABASE.md)
  final String startTime; // "HH:mm" format (e.g., "09:00")
  final String endTime;   // "HH:mm" format (e.g., "17:00")

  AvailableTime({
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
}