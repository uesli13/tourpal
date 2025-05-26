import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tourpal/features/tours/presentation/bloc/tour_plan_bloc.dart';
import 'package:tourpal/features/tours/presentation/bloc/tour_plan_state.dart';
import '../../../../core/utils/logger.dart';
import '../bloc/tour_bloc.dart';
import '../bloc/tour_state.dart';

/// Global BLoC listener for Tour state changes
class TourBlocListener extends StatelessWidget {
  final Widget child;

  const TourBlocListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to TourBloc for creation, publishing, drafts
        BlocListener<TourBloc, TourState>(
          listener: (context, state) {
            _handleTourStateChange(context, state);
          },
        ),
        // Keep existing TourPlanBloc listener for backward compatibility
        BlocListener<TourPlanBloc, TourPlanState>(
          listener: (context, state) {
            _handleTourPlanStateChange(context, state);
          },
        ),
      ],
      child: child,
    );
  }

  void _handleTourStateChange(BuildContext context, TourState state) {
    switch (state.runtimeType) {
      case const (TourCreateSuccess):
        final successState = state as TourCreateSuccess;
        AppLogger.info('Tour creation success: ${successState.tour.title}');
        _showSuccessMessage(context, '🎉 Tour "${successState.tour.title}" created successfully!');
        break;

      case const (TourDraftSaved):
        final draftState = state as TourDraftSaved;
        AppLogger.info('Tour draft saved: ${draftState.tour.title}');
        _showSuccessMessage(context, '📝 Draft "${draftState.tour.title}" saved successfully!');
        break;

      case const (TourPublished):
        final publishState = state as TourPublished;
        AppLogger.info('Tour published: ${publishState.tour.title}');
        _showSuccessMessage(context, '🚀 Tour "${publishState.tour.title}" published successfully!');
        break;

      case const (TourUpdateSuccess):
        final updateState = state as TourUpdateSuccess;
        AppLogger.info('Tour update success: ${updateState.tour.title}');
        _showSuccessMessage(context, '✅ Tour "${updateState.tour.title}" updated successfully!');
        break;

      case const (TourDeleteSuccess):
        final deleteState = state as TourDeleteSuccess;
        AppLogger.info('Tour deletion success: ${deleteState.tourId}');
        _showSuccessMessage(context, '🗑️ Tour deleted successfully!');
        break;

      case const (TourValidationError):
        final validationState = state as TourValidationError;
        AppLogger.error('Tour validation error: ${validationState.errors.join(', ')}');
        _showErrorMessage(context, 'Validation Error: ${validationState.errors.join(', ')}');
        break;

      case const (TourError):
        final errorState = state as TourError;
        AppLogger.error('Tour error: ${errorState.message}');
        _showErrorMessage(context, errorState.message);
        break;

      default:
        AppLogger.debug('Tour state change: ${state.runtimeType}');
        break;
    }
  }

  void _handleTourPlanStateChange(BuildContext context, TourPlanState state) {
    // ...existing code...
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}