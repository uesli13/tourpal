import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/guide.dart';
import '../../../../models/available_time.dart'; // Add this import

class GuideScheduleScreen extends StatefulWidget {
  const GuideScheduleScreen({super.key});

  @override
  State<GuideScheduleScreen> createState() => _GuideScheduleScreenState();
}

class _GuideScheduleScreenState extends State<GuideScheduleScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  Guide? _guide;
  
  final List<String> _weekDays = [
    'Monday',
    'Tuesday', 
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Store availability for each day
  Map<String, Map<String, dynamic>> _weeklySchedule = {};

  @override
  void initState() {
    super.initState();
    _loadGuideData();
  }

  Future<void> _loadGuideData() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Load guide data from Firestore
      final guideDoc = await FirebaseFirestore.instance
          .collection('guides')
          .doc(currentUser.uid)
          .get();

      if (!mounted) return;

      if (guideDoc.exists) {
        _guide = Guide.fromMap(guideDoc.data()!);
        _initializeSchedule();
      } else {
        // Initialize empty schedule if guide doesn't exist yet
        _initializeEmptySchedule();
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load schedule: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeSchedule() {
    _weeklySchedule.clear();
    
    for (int i = 0; i < _weekDays.length; i++) {
      String day = _weekDays[i];
      // Find existing availability for this day (1=Monday, 7=Sunday)
      final dayOfWeekInt = i + 1;
      final existingAvailability = _guide?.availability
          .where((avail) => avail.dayOfWeek == dayOfWeekInt)
          .toList() ?? [];

      if (existingAvailability.isNotEmpty) {
        final avail = existingAvailability.first;
        _weeklySchedule[day] = {
          'isEnabled': true, // If availability exists, it's enabled
          'startTime': TimeOfDay(
            hour: int.parse(avail.startTime.split(':')[0]),
            minute: int.parse(avail.startTime.split(':')[1]),
          ),
          'endTime': TimeOfDay(
            hour: int.parse(avail.endTime.split(':')[0]),
            minute: int.parse(avail.endTime.split(':')[1]),
          ),
        };
      } else {
        _weeklySchedule[day] = {
          'isEnabled': false,
          'startTime': const TimeOfDay(hour: 9, minute: 0),
          'endTime': const TimeOfDay(hour: 17, minute: 0),
        };
      }
    }
  }

  void _initializeEmptySchedule() {
    _weeklySchedule.clear();
    
    for (String day in _weekDays) {
      _weeklySchedule[day] = {
        'isEnabled': false,
        'startTime': const TimeOfDay(hour: 9, minute: 0),
        'endTime': const TimeOfDay(hour: 17, minute: 0),
      };
    }
  }

  Future<void> _saveSchedule() async {
    try {
      setState(() {
        _isSaving = true;
        _error = null;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Convert schedule to AvailableTime list
      List<AvailableTime> availabilityList = [];
      
      for (int i = 0; i < _weekDays.length; i++) {
        String day = _weekDays[i];
        Map<String, dynamic> schedule = _weeklySchedule[day]!;
        
        if (schedule['isEnabled'] == true) {
          final startTime = schedule['startTime'] as TimeOfDay;
          final endTime = schedule['endTime'] as TimeOfDay;
          
          availabilityList.add(AvailableTime(
            dayOfWeek: i + 1, // 1=Monday, 7=Sunday
            startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
            endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
          ));
        }
      }

      // Update or create guide document
      final guideData = {
        'userId': currentUser.uid,
        'bio': _guide?.bio ?? '',
        'languages': _guide?.languages ?? [],
        'isAvailable': availabilityList.isNotEmpty,
        'availability': availabilityList.map((avail) => avail.toMap()).toList(),
      };

      await FirebaseFirestore.instance
          .collection('guides')
          .doc(currentUser.uid)
          .set(guideData, SetOptions(merge: true));

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Schedule saved successfully! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save schedule: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _selectTime(String day, bool isStartTime) async {
    final currentTime = _weeklySchedule[day]![isStartTime ? 'startTime' : 'endTime'] as TimeOfDay;
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
      helpText: isStartTime ? 'Select start time' : 'Select end time',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _weeklySchedule[day]![isStartTime ? 'startTime' : 'endTime'] = picked;
        
        // Validate time range
        final startTime = _weeklySchedule[day]!['startTime'] as TimeOfDay;
        final endTime = _weeklySchedule[day]!['endTime'] as TimeOfDay;
        
        if (endTime.hour < startTime.hour || 
            (endTime.hour == startTime.hour && endTime.minute <= startTime.minute)) {
          // If end time is before or equal to start time, adjust it
          _weeklySchedule[day]!['endTime'] = TimeOfDay(
            hour: startTime.hour + 1,
            minute: startTime.minute,
          );
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Set Your Schedule',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.secondary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
            tooltip: 'Help',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : _error != null
              ? _buildErrorState()
              : _buildScheduleContent(),
      bottomNavigationBar: _isLoading || _error != null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Schedule',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGuideData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 20),
          _buildWeeklySchedule(),
          const SizedBox(height: 100), // Extra space for bottom button
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundLight,
            AppColors.gray50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppColors.secondary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Weekly Availability',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Set your availability for each day of the week. Travelers will be able to book tours during these times.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            label: 'Enable All',
            icon: Icons.check_circle_outline,
            onTap: () {
              setState(() {
                for (String day in _weekDays) {
                  _weeklySchedule[day]!['isEnabled'] = true;
                }
              });
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            label: 'Disable All',
            icon: Icons.cancel_outlined,
            onTap: () {
              setState(() {
                for (String day in _weekDays) {
                  _weeklySchedule[day]!['isEnabled'] = false;
                }
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondary,
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ..._weekDays.map((day) => _buildDayScheduleCard(day)),
      ],
    );
  }

  Widget _buildDayScheduleCard(String day) {
    final daySchedule = _weeklySchedule[day]!;
    final isEnabled = daySchedule['isEnabled'] as bool;
    final startTime = daySchedule['startTime'] as TimeOfDay;
    final endTime = daySchedule['endTime'] as TimeOfDay;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled 
              ? AppColors.secondary
              : AppColors.gray200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    _weeklySchedule[day]!['isEnabled'] = value;
                  });
                },
                activeColor: AppColors.secondary,
              ),
            ],
          ),
          if (isEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeSelector(
                    label: 'Start Time',
                    time: startTime,
                    onTap: () => _selectTime(day, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimeSelector(
                    label: 'End Time',
                    time: endTime,
                    onTap: () => _selectTime(day, false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimeOfDay(time),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.secondary),
            const SizedBox(width: 8),
            const Text('Schedule Help'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 How to set your schedule:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Toggle days on/off using the switches'),
            Text('• Tap time buttons to change start/end times'),
            Text('• Use quick actions to enable/disable all days'),
            Text('• Save your changes when done'),
            SizedBox(height: 12),
            Text(
              '💡 Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Travelers can only book during your available hours'),
            Text('• You can update your schedule anytime')
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: TextStyle(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}