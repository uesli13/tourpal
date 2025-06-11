import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/tour_session.dart';
import '../../../../models/tour_plan.dart';

class TourReadinessWidget extends StatelessWidget {
  final TourSession tourSession;
  final TourPlan tourPlan;
  final bool isReady;
  final bool hasLocationPermission;
  final VoidCallback onMarkReady;
  final bool isGuide;

  const TourReadinessWidget({
    super.key,
    required this.tourSession,
    required this.tourPlan,
    required this.isReady,
    required this.hasLocationPermission,
    required this.onMarkReady,
    required this.isGuide,
  });

  @override
  Widget build(BuildContext context) {
    final readinessChecks = _getReadinessChecks();
    final allChecksComplete = readinessChecks.every((check) => check['completed'] as bool);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Tour Readiness',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Readiness checks
          ...readinessChecks.map((check) {
            final isCompleted = check['completed'] as bool;
            final title = check['title'] as String;
            final subtitle = check['subtitle'] as String;
            final icon = check['icon'] as IconData;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted 
                  ? Colors.green.withOpacity(0.05)
                  : Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : icon,
                    color: isCompleted ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isCompleted ? Colors.green[700] : Colors.orange[800],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isCompleted ? Colors.green[600] : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          // Tour details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tour Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.route, 'Places to Visit', '${tourPlan.places.length} locations'),
                _buildDetailRow(Icons.schedule, 'Estimated Duration', '2-3 hours'), // Using default since estimatedDuration doesn't exist
                _buildDetailRow(Icons.people, 'Group Size', '2 participants'), // Guide + Traveler
                _buildDetailRow(Icons.location_on, 'Meeting Point', tourPlan.places.isNotEmpty ? tourPlan.places.first.name : 'First location'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Ready button
          if (!isReady && allChecksComplete) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarkReady,
                icon: const Icon(Icons.done),
                label: Text(
                  isGuide ? 'Mark as Ready to Guide' : 'Mark as Ready',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else if (isReady) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isGuide ? 'Ready to Guide Tour' : 'Ready for Tour',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete All Checks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Please complete all readiness checks above',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getReadinessChecks() {
    return [
      {
        'title': 'Location Permission',
        'subtitle': hasLocationPermission 
          ? 'Location sharing enabled'
          : 'Grant location access to participate',
        'icon': Icons.location_on,
        'completed': hasLocationPermission,
      },
      {
        'title': 'Tour Information',
        'subtitle': 'Review tour details and itinerary',
        'icon': Icons.info,
        'completed': true, // Always completed as they can see the info
      },
      if (isGuide) ...[
        {
          'title': 'Guide Equipment',
          'subtitle': 'Ensure you have necessary guiding materials',
          'icon': Icons.backpack,
          'completed': true, // Assumed completed for now
        },
        {
          'title': 'Route Preparation',
          'subtitle': 'Familiar with all tour locations',
          'icon': Icons.map,
          'completed': true, // Assumed completed for now
        },
      ] else ...[
        {
          'title': 'Personal Items',
          'subtitle': 'Bring water, comfortable shoes, and camera',
          'icon': Icons.backpack,
          'completed': true, // Assumed completed for now
        },
      ],
    ];
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}