import 'package:equatable/equatable.dart';
import '../../../../models/review.dart';

abstract class ReviewEvent extends Equatable {
  const ReviewEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadTourPlanReviewsEvent extends ReviewEvent {
  final String tourPlanId;
  
  const LoadTourPlanReviewsEvent({required this.tourPlanId});
  
  @override
  List<Object> get props => [tourPlanId];
}

class LoadUserReviewsEvent extends ReviewEvent {
  final String userId;
  
  const LoadUserReviewsEvent({required this.userId});
  
  @override
  List<Object> get props => [userId];
}

class LoadReviewByIdEvent extends ReviewEvent {
  final String reviewId;
  
  const LoadReviewByIdEvent({required this.reviewId});
  
  @override
  List<Object> get props => [reviewId];
}

class CreateReviewEvent extends ReviewEvent {
  final String tourPlanId;
  final int rating;
  final String comment;
  final List<String> imageUrls;
  
  const CreateReviewEvent({
    required this.tourPlanId,
    required this.rating,
    required this.comment,
    this.imageUrls = const [],
  });
  
  @override
  List<Object> get props => [tourPlanId, rating, comment, imageUrls];
}

class UpdateReviewEvent extends ReviewEvent {
  final String reviewId;
  final int rating;
  final String comment;
  final List<String> imageUrls;
  
  const UpdateReviewEvent({
    required this.reviewId,
    required this.rating,
    required this.comment,
    this.imageUrls = const [],
  });
  
  @override
  List<Object> get props => [reviewId, rating, comment, imageUrls];
}

class DeleteReviewEvent extends ReviewEvent {
  final String reviewId;
  
  const DeleteReviewEvent({required this.reviewId});
  
  @override
  List<Object> get props => [reviewId];
}

class LoadTourPlanRatingStatsEvent extends ReviewEvent {
  final String tourPlanId;
  
  const LoadTourPlanRatingStatsEvent({required this.tourPlanId});
  
  @override
  List<Object> get props => [tourPlanId];
}

class MarkReviewHelpfulEvent extends ReviewEvent {
  final String reviewId;
  final bool isHelpful;
  
  const MarkReviewHelpfulEvent({
    required this.reviewId,
    required this.isHelpful,
  });
  
  @override
  List<Object> get props => [reviewId, isHelpful];
}

class ReportReviewEvent extends ReviewEvent {
  final String reviewId;
  final String reason;
  
  const ReportReviewEvent({
    required this.reviewId,
    required this.reason,
  });
  
  @override
  List<Object> get props => [reviewId, reason];
}

class FilterReviewsByRatingEvent extends ReviewEvent {
  final List<int> ratingFilters;
  
  const FilterReviewsByRatingEvent({required this.ratingFilters});
  
  @override
  List<Object> get props => [ratingFilters];
}

class FilterReviewsByVerificationEvent extends ReviewEvent {
  final bool? verifiedOnly;
  
  const FilterReviewsByVerificationEvent({this.verifiedOnly});
  
  @override
  List<Object?> get props => [verifiedOnly];
}

class SortReviewsEvent extends ReviewEvent {
  final ReviewSortType sortType;
  
  const SortReviewsEvent({required this.sortType});
  
  @override
  List<Object> get props => [sortType];
}

class SearchReviewsEvent extends ReviewEvent {
  final String query;
  
  const SearchReviewsEvent({required this.query});
  
  @override
  List<Object> get props => [query];
}

class LoadRecentReviewsEvent extends ReviewEvent {
  final int limit;
  
  const LoadRecentReviewsEvent({this.limit = 10});
  
  @override
  List<Object> get props => [limit];
}

class LoadTopReviewsEvent extends ReviewEvent {
  final String tourPlanId;
  final int limit;
  
  const LoadTopReviewsEvent({
    required this.tourPlanId,
    this.limit = 5,
  });
  
  @override
  List<Object> get props => [tourPlanId, limit];
}

class CheckUserCanReviewEvent extends ReviewEvent {
  final String userId;
  final String tourPlanId;
  
  const CheckUserCanReviewEvent({
    required this.userId,
    required this.tourPlanId,
  });
  
  @override
  List<Object> get props => [userId, tourPlanId];
}

class UploadReviewImagesEvent extends ReviewEvent {
  final List<String> imagePaths;
  
  const UploadReviewImagesEvent({required this.imagePaths});
  
  @override
  List<Object> get props => [imagePaths];
}

class RefreshReviewsEvent extends ReviewEvent {
  const RefreshReviewsEvent();
}

class ClearReviewErrorEvent extends ReviewEvent {
  const ClearReviewErrorEvent();
}

class ResetReviewFiltersEvent extends ReviewEvent {
  const ResetReviewFiltersEvent();
}

enum ReviewSortType {
  newest,
  oldest,
  highestRating,
  lowestRating,
  mostHelpful,
}

extension ReviewSortTypeExtension on ReviewSortType {
  String get displayName {
    switch (this) {
      case ReviewSortType.newest:
        return 'Newest First';
      case ReviewSortType.oldest:
        return 'Oldest First';
      case ReviewSortType.highestRating:
        return 'Highest Rating';
      case ReviewSortType.lowestRating:
        return 'Lowest Rating';
      case ReviewSortType.mostHelpful:
        return 'Most Helpful';
    }
  }
}