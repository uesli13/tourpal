import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/guide_availability_service.dart';
import '../../../../models/available_time.dart';

class AvailabilityCalendarWidget extends StatefulWidget {
  final String guideId;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const AvailabilityCalendarWidget({
    super.key,
    required this.guideId,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<AvailabilityCalendarWidget> createState() => _AvailabilityCalendarWidgetState();
}

class _AvailabilityCalendarWidgetState extends State<AvailabilityCalendarWidget> {
  final GuideAvailabilityService _availabilityService = GuideAvailabilityService();
  
  DateTime _focusedDay = DateTime.now();
  List<AvailableTime> _guideSchedule = [];
  Map<DateTime, bool> _dayAvailabilityCache = {};
  bool _loadingSchedule = true;

  @override
  void initState() {
    super.initState();
    _loadGuideSchedule();
  }

  Future<void> _loadGuideSchedule() async {
    try {
      final schedule = await _availabilityService.getGuideWeeklySchedule(widget.guideId);
      setState(() {
        _guideSchedule = schedule;
        _loadingSchedule = false;
      });
      _precomputeAvailability();
    } catch (e) {
      setState(() {
        _loadingSchedule = false;
      });
      print('Error loading guide schedule: $e');
    }
  }

  void _precomputeAvailability() {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 90)); // 3 months ahead
    
    for (DateTime date = now; date.isBefore(endDate); date = date.add(const Duration(days: 1))) {
      _dayAvailabilityCache[_dateOnly(date)] = _isDateAvailable(date);
    }
  }

  bool _isDateAvailable(DateTime date) {
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false; // Past dates not available
    }
    
    final dayOfWeek = date.weekday % 7; // Convert to 0-based (Sunday=0)
    return _guideSchedule.any((schedule) => schedule.dayOfWeek == dayOfWeek);
  }

  String _getAvailabilityTimes(DateTime date) {
    final dayOfWeek = date.weekday % 7;
    final daySchedules = _guideSchedule.where((s) => s.dayOfWeek == dayOfWeek).toList();
    
    if (daySchedules.isEmpty) return '';
    
    final times = daySchedules.map((s) => '${s.startTime}-${s.endTime}').join(', ');
    return times;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSchedule) {
      return Container(
        // Remove fixed height to avoid intrinsic dimensions conflict
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min size instead of center
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading guide availability...'),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum size needed
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Select Date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          
          // Calendar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar<String>(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) {
                return widget.selectedDate != null && isSameDay(widget.selectedDate!, day);
              },
              enabledDayPredicate: (day) {
                return _dayAvailabilityCache[_dateOnly(day)] ?? false;
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (_dayAvailabilityCache[_dateOnly(selectedDay)] ?? false) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  widget.onDateSelected(selectedDay);
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: AppColors.textPrimary),
                holidayTextStyle: const TextStyle(color: AppColors.textPrimary),
                
                // Available days styling
                defaultTextStyle: const TextStyle(color: AppColors.textSecondary),
                defaultDecoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                
                // Selected day styling
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                
                // Today styling
                todayTextStyle: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                
                // Disabled days styling
                disabledTextStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
                disabledDecoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppColors.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
                weekendStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final isAvailable = _dayAvailabilityCache[_dateOnly(day)] ?? false;
                  
                  if (!isAvailable) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  // Available day with green indicator
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Legend
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Legend:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade200),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Available',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Unavailable',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                
                // Show availability times for selected date
                if (widget.selectedDate != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Times:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getAvailabilityTimes(widget.selectedDate!).isNotEmpty 
                              ? _getAvailabilityTimes(widget.selectedDate!) 
                              : 'No times available',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}