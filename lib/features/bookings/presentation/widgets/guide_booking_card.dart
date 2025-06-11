import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/booking.dart';
import '../../../../models/tour_plan.dart';
import '../../../../models/user.dart';

class GuideBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onViewDetails;
  final VoidCallback? onStartTour;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const GuideBookingCard({
    super.key,
    required this.booking,
    this.onViewDetails,
    this.onStartTour,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppColors.backgroundLight.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header with status and tour info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(booking.status).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatusChip(booking.status),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(booking.startTime.toDate()),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Tour Plan Info
                  FutureBuilder<TourPlan?>(
                    future: _getTourPlan(booking.tourPlanId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final tour = snapshot.data!;
                        return Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.backgroundLight,
                                image: tour.coverImageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(tour.coverImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: tour.coverImageUrl == null
                                  ? Icon(Icons.tour, color: AppColors.primary)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tour.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${tour.duration}h',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                                      Text(
                                        '\$${tour.price.toInt()}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.backgroundLight,
                            ),
                            child: Icon(Icons.tour, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Loading tour details...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Traveler Information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FutureBuilder<User?>(
                    future: _getTraveler(booking.travelerId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final traveler = snapshot.data!;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outline.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: traveler.hasProfileImage
                                    ? NetworkImage(traveler.profileImageUrl!)
                                    : null,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: !traveler.hasProfileImage
                                    ? Icon(Icons.person, color: AppColors.primary, size: 20)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      traveler.displayName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Booked ${_formatRelativeTime(booking.bookedAt.toDate())}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                ),
                            ],
                          ),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Icon(Icons.person, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Loading traveler details...',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  // Action Buttons
                  if (booking.status == 'pending') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCancel,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Decline'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: onConfirm,
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Accept Booking'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (booking.status == 'confirmed' || booking.status == 'checked_in') ...[
                    const SizedBox(height: 16),
                    // Check if tour is scheduled for today and show appropriate buttons
                    if (_isScheduledForToday(booking.startTime.toDate())) ...[
                      // Today's tour - show Start Tour button prominently
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: onStartTour,
                              icon: const Icon(Icons.play_arrow, size: 20),
                              label: const Text('Start Tour'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.guide,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onViewDetails,
                                  icon: const Icon(Icons.map, size: 18),
                                  label: const Text('View Tour'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(color: AppColors.primary),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      // Future tour - show standard buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onViewDetails,
                              icon: const Icon(Icons.map, size: 18),
                              label: const Text('View Tour'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ] else if (booking.status == 'completed') ...[
                    const SizedBox(height: 16),
                    // Completed tour - show view details only
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onViewDetails,
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('View Details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo['backgroundColor'],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusInfo['color'].withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo['icon'],
            size: 14,
            color: statusInfo['color'],
          ),
          const SizedBox(width: 6),
          Text(
            statusInfo['text'],
            style: TextStyle(
              color: statusInfo['color'],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'backgroundColor': Colors.orange.shade100,
          'color': Colors.orange.shade700,
          'text': 'Pending Review',
          'icon': Icons.schedule,
        };
      case 'confirmed':
        return {
          'backgroundColor': Colors.green.shade100,
          'color': Colors.green.shade700,
          'text': 'Confirmed',
          'icon': Icons.check_circle,
        };
      case 'checked_in':  // Add support for checked_in status
        return {
          'backgroundColor': Colors.blue.shade100,
          'color': Colors.blue.shade700,
          'text': 'Checked In',
          'icon': Icons.login,
        };
      case 'completed':
        return {
          'backgroundColor': Colors.blue.shade100,
          'color': Colors.blue.shade700,
          'text': 'Completed',
          'icon': Icons.done_all,
        };
      case 'cancelled':
        return {
          'backgroundColor': Colors.red.shade100,
          'color': Colors.red.shade700,
          'text': 'Cancelled',
          'icon': Icons.cancel,
        };
      default:
        return {
          'backgroundColor': Colors.grey.shade100,
          'color': Colors.grey.shade700,
          'text': status.toUpperCase().replaceAll('_', ' '),
          'icon': Icons.info,
        };
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'checked_in':  // Add support for checked_in status
        return Colors.blue;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${weekdays[dateTime.weekday - 1]} ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<TourPlan?> _getTourPlan(String tourPlanId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tourPlans')
          .doc(tourPlanId)
          .get();
      
      if (doc.exists) {
        return TourPlan.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error fetching tour plan: $e');
    }
    return null;
  }

  Future<User?> _getTraveler(String travelerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(travelerId)
          .get();
      
      if (doc.exists) {
        return User.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Error fetching traveler: $e');
    }
    return null;
  }

  bool _isScheduledForToday(DateTime scheduleTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduleDate = DateTime(scheduleTime.year, scheduleTime.month, scheduleTime.day);
    return scheduleDate.isAtSameMomentAs(today);
  }
}