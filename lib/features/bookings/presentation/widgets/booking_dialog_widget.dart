import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/tour_plan.dart';
import '../../../../models/user.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';
import 'availability_calendar_widget.dart';
import 'time_selection_widget.dart';

class BookingDialogWidget extends StatefulWidget {
  final User guide;
  final TourPlan tour;

  const BookingDialogWidget({
    super.key,
    required this.guide,
    required this.tour,
  });

  @override
  State<BookingDialogWidget> createState() => _BookingDialogWidgetState();
}

class _BookingDialogWidgetState extends State<BookingDialogWidget> {
  DateTime? _selectedDate;
  DateTime? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingSuccess) {
          Navigator.of(context).pop();
          _showBookingSuccessDialog();
        } else if (state is BookingError) {
          Navigator.of(context).pop();
          _showBookingErrorDialog(state.message);
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 400,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.book_online, color: AppColors.tourist),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Book "${widget.tour.title}"',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Guide Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: widget.guide.hasProfileImage
                                  ? NetworkImage(widget.guide.profileImageUrl!)
                                  : null,
                              backgroundColor: AppColors.backgroundLight,
                              child: !widget.guide.hasProfileImage
                                  ? const Icon(Icons.person, color: AppColors.tourist)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Guide: ${widget.guide.displayName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Tour: ${widget.tour.title}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    'Price: \$${widget.tour.price.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.tourist, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Step 1: Date Selection
                      AvailabilityCalendarWidget(
                        guideId: widget.guide.id,
                        selectedDate: _selectedDate,
                        onDateSelected: _onDateSelected,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Step 2: Time Selection (shown only after date is selected)
                      if (_selectedDate != null) ...[
                        TimeSelectionWidget(
                          guideId: widget.guide.id,
                          selectedDate: _selectedDate!,
                          selectedTime: _selectedTime,
                          onTimeSelected: _onTimeSelected,
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                      
                      // Booking Summary
                      if (_selectedDate != null && _selectedTime != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.success),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.event_note, color: AppColors.success, size: 16),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Booking Summary',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Date: ${_formatDate(_selectedDate!)}', style: const TextStyle(fontSize: 12)),
                              Text('Time: ${_formatTime(_selectedTime!)}', style: const TextStyle(fontSize: 12)),
                              Text('Duration: ${widget.tour.duration}h', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                'Total: \$${widget.tour.price.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tourist),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    BlocBuilder<BookingBloc, BookingState>(
                      builder: (context, state) {
                        final isLoading = state is BookingLoading;
                        final canBook = _selectedDate != null && _selectedTime != null && !isLoading;
                        
                        return ElevatedButton(
                          onPressed: canBook ? _createBooking : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.tourist,
                            foregroundColor: Colors.white,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Confirm Booking'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTime = null; // Reset time selection
    });
  }

  void _onTimeSelected(DateTime time) {
    setState(() {
      _selectedTime = time;
    });
  }

  void _createBooking() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && _selectedTime != null) {
      context.read<BookingBloc>().add(
        BookTourEvent(
          tourInstanceId: widget.tour.id,
          travelerId: authState.user.id,
          startTime: Timestamp.fromDate(_selectedTime!),
        ),
      );
    }
  }

  void _showBookingSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Booking Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your booking for "${widget.tour.title}" has been requested successfully!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedDate != null && _selectedTime != null)
                    Text(
                      'Date: ${_formatDate(_selectedDate!)}\n'
                      'Time: ${_formatTime(_selectedTime!)}\n'
                      'Guide: ${widget.guide.name}\n'
                      'Price: \$${widget.tour.price.toInt()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Great!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBookingErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 8),
            Text('Booking Failed'),
          ],
        ),
        content: Text(
          'Sorry, we couldn\'t process your booking request.\n\n'
          'Error: $message\n\n'
          'Please try again or contact support if the problem persists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // The dialog is already open, so no need to retry
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    
    return '$weekday, $month ${date.day}, ${date.year}';
  }
}