import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/tour_session.dart';

class TourConfirmationDialog extends StatelessWidget {
  final TourSession session;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  const TourConfirmationDialog({
    super.key,
    required this.session,
    required this.onConfirm,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tour Confirmation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your guide is ready to start the tour.'),
          const SizedBox(height: 16),
          const Text('Are you ready to begin?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onDecline,
          child: const Text('Not Ready'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('I\'m Ready!'),
        ),
      ],
    );
  }
} 