import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/requests/tour_plan_create_request.dart';
import '../../../../models/requests/tour_plan_update_request.dart';
import '../bloc/tour_plan_bloc.dart';
import '../bloc/tour_plan_event.dart';

/// Integration service for TourForm following TourPal BLoC architecture
class TourFormIntegration {
  static const String _tag = 'TourFormIntegration';

  /// Create a new tour plan
  static void createTourPlan(
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
    try {
      AppLogger.info('$_tag: Creating tour plan - $title');
      
      final request = TourPlanCreateRequest(
        title: title,
        description: description,
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

      context.read<TourPlanBloc>().add(CreateTourPlanEvent(request: request));
      AppLogger.info('$_tag: Tour plan creation event dispatched');
    } catch (e) {
      AppLogger.error('$_tag: Failed to create tour plan', e);
    }
  }

  /// Update an existing tour plan
  static void updateTourPlan(
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
    try {
      AppLogger.info('$_tag: Updating tour plan - $tourPlanId');
      
      final request = TourPlanUpdateRequest(
        title: title,
        description: description,
        duration: duration,
        difficulty: difficulty,
        tags: tags,
        isPublic: isPublic,
        imageUrl: imageUrl,
        price: price,
      );

      context.read<TourPlanBloc>().add(UpdateTourPlanEvent(
        tourPlanId: tourPlanId,
        request: request,
      ));
      AppLogger.info('$_tag: Tour plan update event dispatched');
    } catch (e) {
      AppLogger.error('$_tag: Failed to update tour plan', e);
    }
  }

  /// Delete a tour plan
  static void deleteTourPlan(
    BuildContext context, {
    required String tourPlanId,
    required String guideId,
  }) {
    try {
      AppLogger.info('$_tag: Deleting tour plan - $tourPlanId');
      
      context.read<TourPlanBloc>().add(DeleteTourPlanEvent(
        tourPlanId: tourPlanId,
        guideId: guideId,
      ));
      AppLogger.info('$_tag: Tour plan deletion event dispatched');
    } catch (e) {
      AppLogger.error('$_tag: Failed to delete tour plan', e);
    }
  }
}