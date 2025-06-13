import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/user.dart';
import '../../../../models/tour_plan.dart';
import '../../../bookings/presentation/widgets/booking_dialog_widget.dart';

class GuideDetailsDialog extends StatelessWidget {
  final User guide;
  final TourPlan tourPlan;

  const GuideDetailsDialog({
    super.key,
    required this.guide,
    required this.tourPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  colors: [AppColors.guide, AppColors.guide.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: guide.hasProfileImage
                        ? NetworkImage(guide.profileImageUrl!)
                        : null,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: !guide.hasProfileImage
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    guide.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: guide.isAvailable ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        guide.isAvailable ? 'Available' : 'Busy',
                        style: TextStyle(
                          fontSize: 14,
                          color: guide.isAvailable ? Colors.green.shade100 : Colors.orange.shade100,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Guide details content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bio section
                    if (guide.bio != null && guide.bio!.isNotEmpty) ...[
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
                        guide.bio!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Languages section
                    if (guide.languages.isNotEmpty) ...[
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
                        spacing: 6,
                        runSpacing: 6,
                        children: guide.languages.map((language) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.guide.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.guide.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            language,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.guide,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    // Tour information
                    const Text(
                      'Tour Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildInfoRow(Icons.tour, 'Tour', tourPlan.title),
                    _buildInfoRow(Icons.schedule, 'Duration', '${tourPlan.duration} hours'),
                    _buildInfoRow(Icons.attach_money, 'Price', '\$${tourPlan.price.toStringAsFixed(0)}'),
                    _buildInfoRow(Icons.terrain, 'Difficulty', tourPlan.difficulty),
                    _buildInfoRow(Icons.place, 'Places', '${tourPlan.places.length} stops'),
                  ],
                ),
              ),
            ),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.guide),
                        foregroundColor: AppColors.guide,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showBookingDialog(context, guide, tourPlan);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tourist,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Book Tour'),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.guide,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
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

  void _showBookingDialog(BuildContext context, User guide, TourPlan tour) {
    showDialog(
      context: context,
      builder: (context) => BookingDialogWidget(
        tour: tour,
        guide: guide,
      ),
    );
  }
}