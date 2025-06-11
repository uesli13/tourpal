import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/user.dart';
import '../../../../models/guide.dart';
import '../../../../models/tour_plan.dart';
import '../../../bookings/presentation/widgets/booking_dialog_widget.dart';

class GuideDetailsDialog extends StatefulWidget {
  final User guide;
  final TourPlan tourPlan;

  const GuideDetailsDialog({
    super.key,
    required this.guide,
    required this.tourPlan,
  });

  @override
  State<GuideDetailsDialog> createState() => _GuideDetailsDialogState();
}

class _GuideDetailsDialogState extends State<GuideDetailsDialog> {
  Guide? _guideDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGuideDetails();
  }

  Future<void> _loadGuideDetails() async {
    try {
      // Since we already have the User object with basic guide info,
      // let's try to fetch additional guide details from the guides collection
      final guideDoc = await FirebaseFirestore.instance
          .collection('guides')
          .doc(widget.guide.id)
          .get();
      
      if (guideDoc.exists) {
        setState(() {
          _guideDetails = Guide.fromMap(guideDoc.data()!);
          _isLoading = false;
        });
      } else {
        // Guide details don't exist in guides collection, 
        // but we can still show the basic info from User object
        setState(() {
          _guideDetails = null; // No extended guide details available
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading guide details: $e');
      setState(() {
        _guideDetails = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with guide avatar and basic info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Guide',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: widget.guide.hasProfileImage
                            ? NetworkImage(widget.guide.profileImageUrl!)
                            : null,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: !widget.guide.hasProfileImage
                            ? const Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.guide.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: widget.guide.isAvailable ? Colors.green : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.guide.isAvailable ? 'Available Now' : 'Currently Busy',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content area
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
                                const SizedBox(height: 8),
                                Text(_error!, textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        )
                      : _buildContent(),
            ),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showBookingDialog(context);
                      },
                      icon: const Icon(Icons.book_online),
                      label: const Text('Book Tour'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio section - from guide details if available, otherwise from user bio
          if (_guideDetails?.bio != null && _guideDetails!.bio!.isNotEmpty) ...[
            const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _guideDetails!.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ] else if (widget.guide.bio != null && widget.guide.bio!.isNotEmpty) ...[
            const Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.guide.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Languages section - from guide details if available, otherwise from user languages
          if (_guideDetails?.languages.isNotEmpty ?? false) ...[
            const Text(
              'Languages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _guideDetails!.languages.map((language) => Chip(
                label: Text(
                  language,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle: const TextStyle(color: AppColors.primary),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
            const SizedBox(height: 20),
          ] else if (widget.guide.languages.isNotEmpty) ...[
            const Text(
              'Languages',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: widget.guide.languages.map((language) => Chip(
                label: Text(
                  language,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle: const TextStyle(color: AppColors.primary),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
          
          // Guide experience info if no extended details are available
          if (_guideDetails == null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verified Guide - Member since ${_formatJoinDate(widget.guide.createdAt)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Tour information
          const Text(
            'Tour Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.tour, 'Tour', widget.tourPlan.title),
          _buildInfoRow(Icons.schedule, 'Duration', '${widget.tourPlan.duration} hours'),
          _buildInfoRow(Icons.attach_money, 'Price', '\$${widget.tourPlan.price.toStringAsFixed(0)}'),
          _buildInfoRow(Icons.location_on, 'Location', widget.tourPlan.location),
          _buildInfoRow(Icons.trending_up, 'Difficulty', widget.tourPlan.difficulty),
          
          const SizedBox(height: 20),
          
          // Next availability (placeholder)
          const Text(
            'Next Available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  widget.guide.isAvailable 
                      ? 'Available today - Contact for scheduling'
                      : 'Contact guide for availability',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatJoinDate(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else {
        return 'Recently';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays < 30) {
        return 'Recently';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else {
        final years = (difference.inDays / 365).floor();
        return '$years year${years > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BookingDialogWidget(
        tour: widget.tourPlan,
        guide: widget.guide,
      ),
    );
  }
}