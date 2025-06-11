import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TourMapControls extends StatelessWidget {
  final bool isGuide;
  final VoidCallback onBackPressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onCenterLocation;
  final String tourProgress;

  const TourMapControls({
    super.key,
    required this.isGuide,
    required this.onBackPressed,
    required this.onMenuPressed,
    required this.onCenterLocation,
    required this.tourProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onBackPressed,
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Progress indicator
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isGuide ? Icons.person : Icons.location_on,
                  color: isGuide ? AppColors.guide : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isGuide ? 'Guiding Tour' : 'On Tour',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isGuide ? AppColors.guide : AppColors.primary,
                        ),
                      ),
                      Text(
                        'Progress: $tourProgress',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Menu button
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onMenuPressed,
            icon: const Icon(Icons.menu),
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}