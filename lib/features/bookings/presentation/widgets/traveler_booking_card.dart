import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/booking.dart';
import '../../../../models/tour_plan.dart';
import '../../../../models/user.dart';
import '../../../../models/tour_session.dart';

class TravelerBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onViewDetails;
  final VoidCallback? onJoinTour; // New callback for joining active tour
  final VoidCallback? onCancel;
  final VoidCallback? onViewJournal; // New callback for viewing completed tour journal

  const TravelerBookingCard({
    super.key,
    required this.booking,
    this.onViewDetails,
    this.onJoinTour,
    this.onCancel,
    this.onViewJournal,
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
              AppColors.backgroundLight.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header with status and booking info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(booking.status).withValues(alpha: 0.1),
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
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
            
            // Guide Information
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FutureBuilder<User?>(
                    future: _getGuide(booking.tourPlanId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final guide = snapshot.data!;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: guide.hasProfileImage
                                    ? NetworkImage(guide.profileImageUrl!)
                                    : null,
                                backgroundColor: AppColors.guide.withValues(alpha: 0.1),
                                child: !guide.hasProfileImage
                                    ? Icon(Icons.person, color: AppColors.guide, size: 20)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          guide.displayName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.guide.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Guide',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.guide,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Your tour guide',
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
                              backgroundColor: AppColors.guide.withValues(alpha: 0.1),
                              child: Icon(Icons.person, color: AppColors.guide, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Loading guide info...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  Row(
                    children: [
                      if (booking.status == 'pending') ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCancel,
                            icon: const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onViewDetails,
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ] else if (booking.status == 'confirmed') ...[
                        // Check for active tour session with real-time updates
                        StreamBuilder<TourSession?>(
                          stream: _watchActiveTourSession(booking.id),
                          builder: (context, sessionSnapshot) {
                            final session = sessionSnapshot.data;
                            final hasActiveSession = sessionSnapshot.hasData && 
                                session != null &&
                                ((session.status == TourSessionStatus.active ||
                                  session.status == TourSessionStatus.scheduled ||
                                  session.status == TourSessionStatus.waitingForTraveler) ||
                                 // Also check if guide is ready (for backward compatibility)
                                 session.guideReady);
                            
                            if (hasActiveSession) {
                              // Guide has started the tour, show Join Tour button
                              return Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: onJoinTour,
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  label: const Text('Join Tour'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              );
                            } else {
                              // No active session, show waiting message and view details
                              return Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.schedule, size: 14, color: Colors.orange),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'Waiting for guide to start',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: onViewDetails,
                                      icon: const Icon(Icons.visibility, size: 16),
                                      label: const Text('View Details'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ] else if (booking.status == 'completed') ...[
                        // Completed tour - show View Journal button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onViewJournal,
                            icon: const Icon(Icons.book, size: 16),
                            label: const Text('View Journal'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                          const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onViewDetails,
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Cancelled or other status
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onViewDetails,
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View Details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String displayText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        displayText = 'Pending';
        icon = Icons.schedule;
        break;
      case 'confirmed':
        color = Colors.green;
        displayText = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case 'completed':
        color = Colors.blue;
        displayText = 'Completed';
        icon = Icons.done_all;
        break;
      case 'cancelled':
        color = Colors.red;
        displayText = 'Cancelled';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        displayText = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
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
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (bookingDate.isAtSameMomentAs(today)) {
      dateStr = 'Today';
    } else if (bookingDate.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}';
    }
    
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr $timeStr';
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
      AppLogger.logInfo('Error fetching tour plan: $e');
    }
    return null;
  }

  Future<User?> _getGuide(String tourPlanId) async {
    try {
      // First get the tour plan to get the guide ID
      final tourDoc = await FirebaseFirestore.instance
          .collection('tourPlans')
          .doc(tourPlanId)
          .get();
      
      if (tourDoc.exists) {
        final tourData = tourDoc.data()!;
        final guideId = tourData['guideId'] as String;
        
        // Then get the guide user info
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(guideId)
            .get();
        
        if (userDoc.exists) {
          return User.fromMap(userDoc.data()!, userDoc.id);
        }
      }
    } catch (e) {
      AppLogger.logInfo('Error fetching guide: $e');
    }
    return null;
  }

  Stream<TourSession?> _watchActiveTourSession(String bookingId) {
    return FirebaseFirestore.instance
          .collection('tourSessions')
          .where('bookingId', isEqualTo: bookingId)
        .where('status', whereIn: ['active', 'scheduled', 'waitingForTraveler'])
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final sessionData = snapshot.docs.first.data();
        return TourSession.fromMap(sessionData, snapshot.docs.first.id);
    }
    return null;
    });
  }
}