import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../../../models/tour_plan.dart';

abstract class TourCreationEvent extends Equatable {
  const TourCreationEvent();

  @override
  List<Object?> get props => [];
}

class CreateTourEvent extends TourCreationEvent {
  final String title;
  final String description;
  final File? coverImage;
  final List<Map<String, dynamic>> places;
  final double? price;
  final int? duration;
  final String? difficulty;
  final List<String>? tags;

  const CreateTourEvent({
    required this.title,
    required this.description,
    this.coverImage,
    required this.places,
    this.price,
    this.duration,
    this.difficulty,
    this.tags,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    coverImage,
    places,
    price,
    duration,
    difficulty,
    tags,
  ];
}

class ResetTourCreationEvent extends TourCreationEvent {}

class ValidateTourDataEvent extends TourCreationEvent {
  final String title;
  final String description;
  final File? coverImage;
  final List<Map<String, dynamic>> places;

  const ValidateTourDataEvent({
    required this.title,
    required this.description,
    this.coverImage,
    required this.places,
  });

  @override
  List<Object?> get props => [title, description, coverImage, places];
}

class SaveDraftEvent extends TourCreationEvent {
  final String title;
  final String description;
  final File? coverImage;
  final List<Map<String, dynamic>> places;
  final double? price;
  final String? difficulty;
  final List<String>? tags;

  const SaveDraftEvent({
    required this.title,
    required this.description,
    this.coverImage,
    required this.places,
    this.price,
    this.difficulty,
    this.tags,
  });

  @override
  List<Object?> get props => [
    title,
    description,
    coverImage,
    places,
    price,
    difficulty,
    tags,
  ];
}

class UpdateTourEvent extends TourCreationEvent {
  final String tourId;
  final String title;
  final String description;
  final File? coverImage;
  final List<Map<String, dynamic>> places;
  final double? price;
  final String? difficulty;
  final List<String>? tags;
  final TourStatus? status;

  const UpdateTourEvent({
    required this.tourId,
    required this.title,
    required this.description,
    this.coverImage,
    required this.places,
    this.price,
    this.difficulty,
    this.tags,
    this.status,
  });

  @override
  List<Object?> get props => [
    tourId,
    title,
    description,
    coverImage,
    places,
    price,
    difficulty,
    tags,
    status,
  ];
}

class CalculateAutomaticDurationEvent extends TourCreationEvent {
  final List<Map<String, dynamic>> places;

  const CalculateAutomaticDurationEvent({
    required this.places,
  });

  @override
  List<Object?> get props => [places];
}