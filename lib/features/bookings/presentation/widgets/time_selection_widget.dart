import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/guide_availability_service.dart';

class TimeSelectionWidget extends StatefulWidget {
  final String guideId;
  final DateTime selectedDate;
  final DateTime? selectedTime;
  final Function(DateTime) onTimeSelected;

  const TimeSelectionWidget({
    super.key,
    required this.guideId,
    required this.selectedDate,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  @override
  State<TimeSelectionWidget> createState() => _TimeSelectionWidgetState();
}

class _TimeSelectionWidgetState extends State<TimeSelectionWidget> {
  final GuideAvailabilityService _availabilityService = GuideAvailabilityService();
  List<DateTime> _availableTimes = [];
  bool _loadingTimes = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableTimes();
  }

  @override
  void didUpdateWidget(TimeSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadAvailableTimes();
    }
  }

  Future<void> _loadAvailableTimes() async {
    setState(() {
      _loadingTimes = true;
    });

    try {
      final times = await _availabilityService.getAvailableTimeSlotsForDate(
        widget.guideId,
        widget.selectedDate,
      );
      
      setState(() {
        _availableTimes = times;
        _loadingTimes = false;
      });
    } catch (e) {
      setState(() {
        _availableTimes = [];
        _loadingTimes = false;
      });
      AppLogger.logInfo('Error loading available times: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Select Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatSelectedDate(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTimeSelection(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelection() {
    if (_loadingTimes) {
      return Container(
        // Remove fixed height to avoid intrinsic dimensions conflict
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min size instead of fixed height
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Loading available times...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_availableTimes.isEmpty) {
      return Container(
        // Remove fixed height to avoid intrinsic dimensions conflict
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Use min size instead of fixed height
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 32,
                color: Colors.orange.shade600,
              ),
              const SizedBox(height: 8),
              Text(
                'No Available Times',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The guide is not available on this date.\nPlease select a different date.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Group times by morning/afternoon
    final morningTimes = _availableTimes.where((time) => time.hour < 12).toList();
    final afternoonTimes = _availableTimes.where((time) => time.hour >= 12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Morning section
        if (morningTimes.isNotEmpty) ...[
          _buildTimeSection('Morning', morningTimes, Icons.wb_sunny, AppColors.primary),
          const SizedBox(height: 16),
        ],
        
        // Afternoon section
        if (afternoonTimes.isNotEmpty) ...[
          _buildTimeSection('Afternoon', afternoonTimes, Icons.wb_sunny_outlined, AppColors.primary),
        ],
        
        // Summary
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Selected time slots are based on guide availability',
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection(String title, List<DateTime> times, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: times.length,
          itemBuilder: (context, index) {
            final time = times[index];
            final isSelected = widget.selectedTime?.isAtSameMomentAs(time) ?? false;
            
            return _buildTimeSlot(time, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildTimeSlot(DateTime time, bool isSelected) {
    return InkWell(
      onTap: () => widget.onTimeSelected(time),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.backgroundLight
              : Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Use min size to prevent overflow
            children: [
              Flexible( // Make text flexible to prevent overflow
                child: Text(
                  _formatTime(time),
                  style: TextStyle(
                    fontSize: 11, // Reduced font size from 12 to 11
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 1), // Reduced spacing
                Icon(
                  Icons.check_circle,
                  size: 9, // Reduced icon size from 10 to 9
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatSelectedDate() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    final weekday = weekdays[widget.selectedDate.weekday - 1];
    final month = months[widget.selectedDate.month - 1];
    
    return '$weekday, $month ${widget.selectedDate.day}';
  }
}