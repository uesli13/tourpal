import 'package:equatable/equatable.dart';
import 'dart:io';

/// Tour Creation Events following TourPal BLoC architecture rules
abstract class TourCreationEvent extends Equatable {
  const TourCreationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to create and publish a tour
class CreateTourEvent extends TourCreationEvent {
  final String title;
  final String description;
  final File? coverImage;
  final List<Map<String, dynamic>> places;

  const CreateTourEvent({
    required this.title,
    required this.description,
    this.coverImage,
    required this.places,
  });

  @override
  List<Object?> get props => [title, description, coverImage, places];
}

/// Event to save tour as draft
class SaveTourAsDraftEvent extends TourCreationEvent {
  final String title;
  final String description;
  final File? coverImage;
  final List<Map<String, dynamic>> places;

  const SaveTourAsDraftEvent({
    required this.title,
    required this.description,
    this.coverImage,
    required this.places,
  });

  @override
  List<Object?> get props => [title, description, coverImage, places];
}

/// Event to reset tour creation state
class ResetTourCreationEvent extends TourCreationEvent {
  const ResetTourCreationEvent();
}