import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../models/requests/tour_plan_create_request.dart';
import '../../../../models/requests/tour_plan_update_request.dart';
import '../../../../core/utils/logger.dart';
import '../bloc/tour_plan_bloc.dart';
import '../bloc/tour_plan_event.dart';

/// Integration utility for existing tour creation forms with TourPlan BLoC
class TourFormIntegration {
  
  /// Submit tour creation form data to BLoC
  static void submitTourCreation(
    BuildContext context, {
    required String title,
    required String description,
    required String guideId,
    required int duration,
    required String difficulty,
    List<String> tags = const [],
    bool isPublic = true,
    String? imageUrl,
    double? startLatitude,
    double? startLongitude,
    String? startAddress,
  }) {
    AppLogger.info('Submitting tour creation form for: $title');
    
    try {
      // Create the request using correct model structure
      final request = TourPlanCreateRequest(
        title: title.trim(),
        description: description.trim(),
        guideId: guideId,
        duration: duration,
        difficulty: difficulty,
        tags: tags,
        isPublic: isPublic,
        imageUrl: imageUrl,
        startLatitude: startLatitude,
        startLongitude: startLongitude,
        startAddress: startAddress,
      );

      // Dispatch to BLoC
      context.read<TourPlanBloc>().add(CreateTourPlanEvent(request: request));
      
      AppLogger.info('Tour creation request dispatched to BLoC');
    } catch (e) {
      AppLogger.error('Error submitting tour creation form', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting form: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Submit tour update form data to BLoC
  static void submitTourUpdate(
    BuildContext context, {
    required String tourPlanId,
    String? title,
    String? description,
    int? duration,
    String? difficulty,
    List<String>? tags,
    bool? isPublic,
    String? imageUrl,
    double? price,
  }) {
    AppLogger.info('Submitting tour update form for: $tourPlanId');
    
    try {
      final request = TourPlanUpdateRequest(
        title: title?.trim(),
        description: description?.trim(),
        duration: duration,
        difficulty: difficulty,
        tags: tags,
        isPublic: isPublic,
        imageUrl: imageUrl,
        price: price,
      );

      // Check if there are any updates using the model's hasUpdates property
      if (!request.hasUpdates) {
        AppLogger.warning('No updates provided for tour update');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes to save'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Dispatch to BLoC
      context.read<TourPlanBloc>().add(
        UpdateTourPlanEvent(
          tourPlanId: tourPlanId,
          request: request,
        ),
      );
      
      AppLogger.info('Tour update request dispatched to BLoC');
    } catch (e) {
      AppLogger.error('Error submitting tour update form', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating tour: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Delete tour with confirmation
  static void deleteTour(
    BuildContext context, {
    required String tourPlanId,
    required String guideId,
    required String tourTitle,
  }) {
    AppLogger.info('Requesting tour deletion: $tourPlanId');
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Tour'),
        content: Text('Are you sure you want to delete "$tourTitle"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<TourPlanBloc>().add(
                DeleteTourPlanEvent(
                  tourPlanId: tourPlanId,
                  guideId: guideId,
                ),
              );
              AppLogger.info('Tour deletion confirmed and dispatched');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Validate form data before submission
  static String? validateTourForm({
    required String title,
    required String description,
    required int duration,
    required String difficulty,
    required List<String> tags,
  }) {
    if (title.trim().isEmpty) {
      return 'Tour title is required';
    }
    
    if (title.trim().length > 100) {
      return 'Tour title cannot exceed 100 characters';
    }
    
    if (description.trim().isEmpty) {
      return 'Tour description is required';
    }
    
    if (description.trim().length > 500) {
      return 'Tour description cannot exceed 500 characters';
    }
    
    if (duration <= 0) {
      return 'Duration must be greater than 0 minutes';
    }
    
    if (difficulty.trim().isEmpty) {
      return 'Difficulty level is required';
    }
    
    if (tags.isEmpty) {
      return 'Please add at least one tag';
    }
    
    return null; // No validation errors
  }
}