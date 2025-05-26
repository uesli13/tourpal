import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../models/booking.dart';
import '../../../booking/bloc/booking_bloc.dart';
import '../../../booking/bloc/booking_state.dart';
import '../../../booking/bloc/booking_event.dart';

class GuideBookingManagementScreen extends StatelessWidget {
  const GuideBookingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Load guide bookings when screen opens
    context.read<BookingBloc>().add(LoadGuideBookingsEvent());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocListener<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking updated successfully!'), backgroundColor: Colors.green),
            );
            context.read<BookingBloc>().add(LoadGuideBookingsEvent());
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is BookingError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(state.message, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<BookingBloc>().add(LoadGuideBookingsEvent()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            if (state is BookingsLoaded) {
              // Show pending bookings for guides to manage
              final pendingBookings = state.bookings.where((b) => b.status == BookingStatus.pending).toList();
              
              if (pendingBookings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text('No pending bookings', style: AppTextStyles.headingMedium),
                      const SizedBox(height: 8),
                      Text('All caught up!', 
                           style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pendingBookings.length,
                itemBuilder: (context, index) => _buildBookingCard(context, pendingBookings[index]),
              );
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.tourTitle, style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(_formatDate(booking.tourDate), style: AppTextStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.group, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${booking.numberOfPeople} participant${booking.numberOfPeople > 1 ? 's' : ''}', 
                     style: AppTextStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('\$${booking.totalPrice.toStringAsFixed(0)}', style: AppTextStyles.bodyMedium),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptBooking(context, booking.id),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Accept', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectBooking(context, booking.id),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Reject', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _acceptBooking(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => _MessageDialog(
        title: 'Accept Booking',
        buttonText: 'Accept',
        buttonColor: Colors.green,
        hintText: 'Welcome! Looking forward to guiding you...',
        onConfirm: (message) {
          context.read<BookingBloc>().add(UpdateBookingStatusEvent(
            bookingId: bookingId, 
            status: BookingStatus.confirmed,
            message: message,
          ));
        },
      ),
    );
  }

  void _rejectBooking(BuildContext context, String bookingId) {
    showDialog(
      context: context,
      builder: (context) => _MessageDialog(
        title: 'Reject Booking',
        buttonText: 'Reject',
        buttonColor: AppColors.error,
        hintText: 'Sorry, I\'m not available on this date...',
        onConfirm: (message) {
          context.read<BookingBloc>().add(UpdateBookingStatusEvent(
            bookingId: bookingId, 
            status: BookingStatus.cancelled,
            message: message,
          ));
        },
      ),
    );
  }
}

class _MessageDialog extends StatefulWidget {
  final String title;
  final String buttonText;
  final Color buttonColor;
  final String hintText;
  final Function(String) onConfirm;

  const _MessageDialog({
    required this.title,
    required this.buttonText,
    required this.buttonColor,
    required this.hintText,
    required this.onConfirm,
  });

  @override
  State<_MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends State<_MessageDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_controller.text.trim());
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: widget.buttonColor),
          child: Text(widget.buttonText, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}