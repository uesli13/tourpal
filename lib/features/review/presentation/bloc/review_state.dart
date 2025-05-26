import 'package:equatable/equatable.dart';
import 'package:tourpal/features/review/presentation/bloc/review_event.dart';
import '../../../../models/review.dart';
import '../../../../models/rating_statistics.dart';

abstract class ReviewState extends Equatable {
  const ReviewState();
  
  @override
  List<Object?> get props => [];
}

class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

class ReviewsLoading extends ReviewState {
  const ReviewsLoading();
}

class ReviewActionLoading extends ReviewState {
  final String action;
  final String reviewId;
  
  const ReviewActionLoading({
    required this.action,
    required this.reviewId,
  });
  
  @override
  List<Object> get props => [action, reviewId];
}

class ReviewImageUploadLoading extends ReviewState {
  final int uploadedCount;
  final int totalCount;
  
  const ReviewImageUploadLoading({
    required this.uploadedCount,
    required this.totalCount,
  });
  
  @override
  List<Object> get props => [uploadedCount, totalCount];
}

class ReviewLoaded extends ReviewState {
  final Review review;
  
  const ReviewLoaded({required this.review});
  
  @override
  List<Object> get props => [review];
}

class ReviewCreated extends ReviewState {
  final Review review;
  
  const ReviewCreated({required this.review});
  
  @override
  List<Object> get props => [review];
}

class ReviewUpdated extends ReviewState {
  final Review review;
  
  const ReviewUpdated({required this.review});
  
  @override
  List<Object> get props => [review];
}

class ReviewDeleted extends ReviewState {
  final String reviewId;
  
  const ReviewDeleted({required this.reviewId});
  
  @override
  List<Object> get props => [reviewId];
}

class ReviewMarkedHelpful extends ReviewState {
  final Review review;
  final bool wasMarkedHelpful;
  
  const ReviewMarkedHelpful({
    required this.review,
    required this.wasMarkedHelpful,
  });
  
  @override
  List<Object> get props => [review, wasMarkedHelpful];
}

class ReviewReported extends ReviewState {
  final String reviewId;
  final String reason;
  
  const ReviewReported({
    required this.reviewId,
    required this.reason,
  });
  
  @override
  List<Object> get props => [reviewId, reason];
}

class ReviewsLoaded extends ReviewState {
  final List<Review> reviews;
  final ReviewLoadType loadType;
  final String? entityId; // tourPlanId or userId
  
  const ReviewsLoaded({
    required this.reviews,
    required this.loadType,
    this.entityId,
  });
  
  @override
  List<Object?> get props => [reviews, loadType, entityId];
}

class FilteredReviewsLoaded extends ReviewState {
  final List<Review> reviews;
  final List<Review> allReviews;
  final ReviewFilters filters;
  
  const FilteredReviewsLoaded({
    required this.reviews,
    required this.allReviews,
    required this.filters,
  });
  
  @override
  List<Object> get props => [reviews, allReviews, filters];
}

class SortedReviewsLoaded extends ReviewState {
  final List<Review> reviews;
  final List<Review> allReviews;
  final ReviewSortType sortType;
  
  const SortedReviewsLoaded({
    required this.reviews,
    required this.allReviews,
    required this.sortType,
  });
  
  @override
  List<Object> get props => [reviews, allReviews, sortType];
}

class SearchReviewsLoaded extends ReviewState {
  final List<Review> reviews;
  final List<Review> allReviews;
  final String query;
  
  const SearchReviewsLoaded({
    required this.reviews,
    required this.allReviews,
    required this.query,
  });
  
  @override
  List<Object> get props => [reviews, allReviews, query];
}

class TourPlanRatingStatsLoaded extends ReviewState {
  final String tourPlanId;
  final RatingStatistics stats;
  
  const TourPlanRatingStatsLoaded({
    required this.tourPlanId,
    required this.stats,
  });
  
  @override
  List<Object> get props => [tourPlanId, stats];
}

class RecentReviewsLoaded extends ReviewState {
  final List<Review> recentReviews;
  final int totalCount;
  
  const RecentReviewsLoaded({
    required this.recentReviews,
    required this.totalCount,
  });
  
  @override
  List<Object> get props => [recentReviews, totalCount];
}

class TopReviewsLoaded extends ReviewState {
  final List<Review> topReviews;
  final String tourPlanId;
  
  const TopReviewsLoaded({
    required this.topReviews,
    required this.tourPlanId,
  });
  
  @override
  List<Object> get props => [topReviews, tourPlanId];
}

class UserCanReviewChecked extends ReviewState {
  final bool canReview;
  final String userId;
  final String tourPlanId;
  final String? reason; // reason why user cannot review
  
  const UserCanReviewChecked({
    required this.canReview,
    required this.userId,
    required this.tourPlanId,
    this.reason,
  });
  
  @override
  List<Object?> get props => [canReview, userId, tourPlanId, reason];
}

class ReviewImagesUploaded extends ReviewState {
  final List<String> imageUrls;
  
  const ReviewImagesUploaded({required this.imageUrls});
  
  @override
  List<Object> get props => [imageUrls];
}

class ReviewError extends ReviewState {
  final String message;
  final String? errorCode;
  
  const ReviewError({
    required this.message,
    this.errorCode,
  });
  
  @override
  List<Object?> get props => [message, errorCode];
}

class ReviewValidationError extends ReviewState {
  final Map<String, String> fieldErrors;
  final String generalMessage;
  
  const ReviewValidationError({
    required this.fieldErrors,
    required this.generalMessage,
  });
  
  @override
  List<Object> get props => [fieldErrors, generalMessage];
}

class ReviewActionError extends ReviewState {
  final String message;
  final String action;
  final String reviewId;
  
  const ReviewActionError({
    required this.message,
    required this.action,
    required this.reviewId,
  });
  
  @override
  List<Object> get props => [message, action, reviewId];
}

class ReviewImageUploadError extends ReviewState {
  final String message;
  final List<String> failedImages;
  
  const ReviewImageUploadError({
    required this.message,
    required this.failedImages,
  });
  
  @override
  List<Object> get props => [message, failedImages];
}

class ReviewsEmpty extends ReviewState {
  final ReviewLoadType loadType;
  final String message;
  
  const ReviewsEmpty({
    required this.loadType,
    required this.message,
  });
  
  @override
  List<Object> get props => [loadType, message];
}

class NoReviewsFound extends ReviewState {
  final String searchQuery;
  final ReviewFilters? filters;
  
  const NoReviewsFound({
    required this.searchQuery,
    this.filters,
  });
  
  @override
  List<Object?> get props => [searchQuery, filters];
}

enum ReviewLoadType {
  tourPlan,
  user,
  recent,
  top,
  all,
}

class ReviewFilters extends Equatable {
  final List<int> ratingFilters;
  final bool? verifiedOnly;
  final bool? withImagesOnly;
  final DateTime? startDate;
  final DateTime? endDate;
  
  const ReviewFilters({
    this.ratingFilters = const [],
    this.verifiedOnly,
    this.withImagesOnly,
    this.startDate,
    this.endDate,
  });
  
  ReviewFilters copyWith({
    List<int>? ratingFilters,
    bool? verifiedOnly,
    bool? withImagesOnly,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ReviewFilters(
      ratingFilters: ratingFilters ?? this.ratingFilters,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      withImagesOnly: withImagesOnly ?? this.withImagesOnly,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
  
  bool get hasFilters =>
      ratingFilters.isNotEmpty ||
      verifiedOnly != null ||
      withImagesOnly != null ||
      startDate != null ||
      endDate != null;
  
  bool matchesReview(Review review) {
    // Rating filter
    if (ratingFilters.isNotEmpty && !ratingFilters.contains(review.rating)) {
      return false;
    }
    
    // Verification filter
    if (verifiedOnly == true && !review.isVerifiedBooking) {
      return false;
    }
    
    // Images filter
    if (withImagesOnly == true && !review.hasImages) {
      return false;
    }
    
    // Date range filter
    if (startDate != null && review.createdAt.isBefore(startDate!)) {
      return false;
    }
    
    if (endDate != null && review.createdAt.isAfter(endDate!)) {
      return false;
    }
    
    return true;
  }
  
  @override
  List<Object?> get props => [
    ratingFilters,
    verifiedOnly,
    withImagesOnly,
    startDate,
    endDate,
  ];
}

extension ReviewLoadTypeExtension on ReviewLoadType {
  String get displayName {
    switch (this) {
      case ReviewLoadType.tourPlan:
        return 'Tour Plan Reviews';
      case ReviewLoadType.user:
        return 'My Reviews';
      case ReviewLoadType.recent:
        return 'Recent Reviews';
      case ReviewLoadType.top:
        return 'Top Reviews';
      case ReviewLoadType.all:
        return 'All Reviews';
    }
  }
  
  String get emptyMessage {
    switch (this) {
      case ReviewLoadType.tourPlan:
        return 'No reviews for this tour plan yet';
      case ReviewLoadType.user:
        return 'You haven\'t written any reviews yet';
      case ReviewLoadType.recent:
        return 'No recent reviews';
      case ReviewLoadType.top:
        return 'No top reviews available';
      case ReviewLoadType.all:
        return 'No reviews found';
    }
  }
}