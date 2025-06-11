import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TourMapControlsWidget extends StatelessWidget {
  final VoidCallback onLocationPressed;
  final VoidCallback onNextPlace;
  final VoidCallback onPrevPlace;
  final bool canGoNext;
  final bool canGoPrev;

  const TourMapControlsWidget({
    super.key,
    required this.onLocationPressed,
    required this.onNextPlace,
    required this.onPrevPlace,
    required this.canGoNext,
    required this.canGoPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // My Location button
        FloatingActionButton(
          heroTag: "location",
          onPressed: onLocationPressed,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          mini: true,
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(height: 8),
        
        // Next place button
        FloatingActionButton(
          heroTag: "next",
          onPressed: canGoNext ? onNextPlace : null,
          backgroundColor: canGoNext ? AppColors.primary : Colors.grey[300],
          foregroundColor: Colors.white,
          mini: true,
          child: const Icon(Icons.keyboard_arrow_down),
        ),
        const SizedBox(height: 8),
        
        // Previous place button
        FloatingActionButton(
          heroTag: "prev",
          onPressed: canGoPrev ? onPrevPlace : null,
          backgroundColor: canGoPrev ? AppColors.primary : Colors.grey[300],
          foregroundColor: Colors.white,
          mini: true,
          child: const Icon(Icons.keyboard_arrow_up),
        ),
      ],
    );
  }
}