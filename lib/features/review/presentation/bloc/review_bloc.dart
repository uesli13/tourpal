import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../services/review_service.dart';
import '../../../../models/review.dart';
import '../../../../models/rating_statistics.dart';
import 'review_event.dart';
import 'review_state.dart';

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewService _reviewService;
  
  List<Review> _allReviews = [];
  ReviewFilters _currentFilters = const ReviewFilters();
  ReviewSortType _currentSortType = ReviewSortType.newest;
  String _currentSearchQuery = '';

  ReviewBloc({
    required ReviewService reviewService,
  }) : _reviewService = reviewService,
       super(const ReviewInitial()) {
    
    AppLogger.info('ReviewBloc initialized');
    
    on<LoadTourPlanReviewsEvent>(_onLoadTourPlanReviews);
    on<LoadUserReviewsEvent>(_onLoadUserReviews);
    on<LoadReviewByIdEvent>(_onLoadReviewById);
    on<CreateReviewEvent>(_onCreateReview);
    on<UpdateReviewEvent>(_onUpdateReview);
    on<DeleteReviewEvent>(_onDeleteReview);
    on<LoadTourPlanRatingStatsEvent>(_onLoadTourPlanRatingStats);
    on<MarkReviewHelpfulEvent>(_onMarkReviewHelpful);
    on<ReportReviewEvent>(_onReportReview);
    on<FilterReviewsByRatingEvent>(_onFilterReviewsByRating);
    on<FilterReviewsByVerificationEvent>(_onFilterReviewsByVerification);
    on<SortReviewsEvent>(_onSortReviews);
    on<SearchReviewsEvent>(_onSearchReviews);
    on<LoadRecentReviewsEvent>(_onLoadRecentReviews);
    on<LoadTopReviewsEvent>(_onLoadTopReviews);
    on<CheckUserCanReviewEvent>(_onCheckUserCanReview);
    on<UploadReviewImagesEvent>(_onUploadReviewImages);
    on<RefreshReviewsEvent>(_onRefreshReviews);
    on<ClearReviewErrorEvent>(_onClearReviewError);
    on<ResetReviewFiltersEvent>(_onResetReviewFilters);
  }

  @override
  void onChange(Change<ReviewState> change) {
    super.onChange(change);
    AppLogger.blocTransition(
      'ReviewBloc',
      change.currentState.runtimeType.toString(),
      change.nextState.runtimeType.toString(),
    );
  }

  @override
  void onEvent(ReviewEvent event) {
    super.onEvent(event);
    AppLogger.blocEvent('ReviewBloc', event.runtimeType.toString());
  }

  Future<void> _onLoadTourPlanReviews(
    LoadTourPlanReviewsEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading tour plan reviews for ${event.tourPlanId}');
    
    emit(const ReviewsLoading());
    
    try {
      final reviews = await _reviewService.getReviewsByTourPlan(event.tourPlanId);
      _allReviews = reviews;
      
      stopwatch.stop();
      AppLogger.performance('Load Tour Plan Reviews', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'getReviewsByTourPlan', true);
      
      if (reviews.isEmpty) {
        emit(ReviewsEmpty(
          loadType: ReviewLoadType.tourPlan,
          message: ReviewLoadType.tourPlan.emptyMessage,
        ));
      } else {
        emit(ReviewsLoaded(
          reviews: reviews,
          loadType: ReviewLoadType.tourPlan,
          entityId: event.tourPlanId,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load tour plan reviews', e);
      AppLogger.serviceOperation('ReviewService', 'getReviewsByTourPlan', false);
      emit(ReviewError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLoadUserReviews(
    LoadUserReviewsEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading user reviews for ${event.userId}');
    
    emit(const ReviewsLoading());
    
    try {
      final reviews = await _reviewService.getReviewsByUser(event.userId);
      _allReviews = reviews;
      
      stopwatch.stop();
      AppLogger.performance('Load User Reviews', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'getReviewsByUser', true);
      
      if (reviews.isEmpty) {
        emit(ReviewsEmpty(
          loadType: ReviewLoadType.user,
          message: ReviewLoadType.user.emptyMessage,
        ));
      } else {
        emit(ReviewsLoaded(
          reviews: reviews,
          loadType: ReviewLoadType.user,
          entityId: event.userId,
        ));
      }
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load user reviews', e);
      AppLogger.serviceOperation('ReviewService', 'getReviewsByUser', false);
      emit(ReviewError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLoadReviewById(
    LoadReviewByIdEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading review by ID: ${event.reviewId}');
    
    emit(const ReviewLoading());
    
    try {
      final review = await _reviewService.getReviewById(event.reviewId);
      
      stopwatch.stop();
      AppLogger.performance('Load Review By ID', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'getReviewById', true);
      
      emit(ReviewLoaded(review: review));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load review by ID', e);
      AppLogger.serviceOperation('ReviewService', 'getReviewById', false);
      emit(ReviewError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onCreateReview(
    CreateReviewEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Creating review for tour plan ${event.tourPlanId}');
    
    emit(const ReviewLoading());
    
    try {
      // Validate review data
      _validateReviewData(event.rating, event.comment);
      
      final review = await _reviewService.createReview(
        tourPlanId: event.tourPlanId,
        rating: event.rating,
        comment: event.comment,
        imageUrls: event.imageUrls,
      );
      
      stopwatch.stop();
      AppLogger.performance('Create Review', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'createReview', true);
      AppLogger.info('Review created successfully: ${review.id}');
      
      emit(ReviewCreated(review: review));
    } on ValidationException catch (e) {
      stopwatch.stop();
      AppLogger.warning('Review validation failed: ${e.message}');
      emit(ReviewValidationError(
        fieldErrors: _extractFieldErrors(e.message),
        generalMessage: e.message,
      ));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to create review', e);
      AppLogger.serviceOperation('ReviewService', 'createReview', false);
      emit(ReviewError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onUpdateReview(
    UpdateReviewEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Updating review ${event.reviewId}');
    
    emit(ReviewActionLoading(
      action: 'Updating review',
      reviewId: event.reviewId,
    ));
    
    try {
      // Validate review data
      _validateReviewData(event.rating, event.comment);
      
      final updatedReview = await _reviewService.updateReview(
        reviewId: event.reviewId,
        rating: event.rating,
        comment: event.comment,
        imageUrls: event.imageUrls,
      );
      
      stopwatch.stop();
      AppLogger.performance('Update Review', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'updateReview', true);
      AppLogger.info('Review updated successfully: ${event.reviewId}');
      
      emit(ReviewUpdated(review: updatedReview));
    } on ValidationException catch (e) {
      stopwatch.stop();
      AppLogger.warning('Review validation failed: ${e.message}');
      emit(ReviewValidationError(
        fieldErrors: _extractFieldErrors(e.message),
        generalMessage: e.message,
      ));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to update review', e);
      AppLogger.serviceOperation('ReviewService', 'updateReview', false);
      emit(ReviewActionError(
        message: _getErrorMessage(e),
        action: 'update',
        reviewId: event.reviewId,
      ));
    }
  }

  Future<void> _onDeleteReview(
    DeleteReviewEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Deleting review ${event.reviewId}');
    
    emit(ReviewActionLoading(
      action: 'Deleting review',
      reviewId: event.reviewId,
    ));
    
    try {
      await _reviewService.deleteReview(event.reviewId);
      
      stopwatch.stop();
      AppLogger.performance('Delete Review', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'deleteReview', true);
      AppLogger.info('Review deleted successfully: ${event.reviewId}');
      
      emit(ReviewDeleted(reviewId: event.reviewId));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to delete review', e);
      AppLogger.serviceOperation('ReviewService', 'deleteReview', false);
      emit(ReviewActionError(
        message: _getErrorMessage(e),
        action: 'delete',
        reviewId: event.reviewId,
      ));
    }
  }

  Future<void> _onLoadTourPlanRatingStats(
    LoadTourPlanRatingStatsEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading rating stats for tour plan ${event.tourPlanId}');
    
    emit(const ReviewsLoading());
    
    try {
      final stats = await _reviewService.getTourPlanRatingStats(event.tourPlanId);
      
      // Convert Map<String, dynamic> to RatingStatistics object
      final ratingStats = RatingStatistics.fromMap(stats);
      
      stopwatch.stop();
      AppLogger.performance('Load Rating Stats', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'getTourPlanRatingStats', true);
      
      emit(TourPlanRatingStatsLoaded(
        tourPlanId: event.tourPlanId,
        stats: ratingStats,
      ));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load rating stats', e);
      AppLogger.serviceOperation('ReviewService', 'getTourPlanRatingStats', false);
      emit(ReviewError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onMarkReviewHelpful(
    MarkReviewHelpfulEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Marking review ${event.reviewId} as helpful');
    
    emit(ReviewActionLoading(
      action: 'Updating helpfulness',
      reviewId: event.reviewId,
    ));
    
    try {
      final updatedReview = await _reviewService.markReviewHelpful(event.reviewId);
      
      stopwatch.stop();
      AppLogger.performance('Mark Review Helpful', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'markReviewHelpful', true);
      
      emit(ReviewMarkedHelpful(
        review: updatedReview,
        wasMarkedHelpful: true,
      ));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to mark review helpful', e);
      AppLogger.serviceOperation('ReviewService', 'markReviewHelpful', false);
      emit(ReviewActionError(
        message: _getErrorMessage(e),
        action: 'mark helpful',
        reviewId: event.reviewId,
      ));
    }
  }

  Future<void> _onReportReview(
    ReportReviewEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Reporting review ${event.reviewId} for: ${event.reason}');
    
    emit(ReviewActionLoading(
      action: 'Reporting review',
      reviewId: event.reviewId,
    ));
    
    try {
      await _reviewService.reportReview(
        reviewId: event.reviewId,
        reason: event.reason,
      );
      
      stopwatch.stop();
      AppLogger.performance('Report Review', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'reportReview', true);
      AppLogger.info('Review reported successfully: ${event.reviewId}');
      
      emit(ReviewReported(
        reviewId: event.reviewId,
        reason: event.reason,
      ));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to report review', e);
      AppLogger.serviceOperation('ReviewService', 'reportReview', false);
      emit(ReviewActionError(
        message: _getErrorMessage(e),
        action: 'report',
        reviewId: event.reviewId,
      ));
    }
  }

  Future<void> _onFilterReviewsByRating(
    FilterReviewsByRatingEvent event,
    Emitter<ReviewState> emit,
  ) async {
    AppLogger.info('Filtering reviews by rating: ${event.ratingFilters.join(', ')}');
    
    _currentFilters = _currentFilters.copyWith(ratingFilters: event.ratingFilters);
    _applyFiltersAndSearch(emit);
  }

  Future<void> _onFilterReviewsByVerification(
    FilterReviewsByVerificationEvent event,
    Emitter<ReviewState> emit,
  ) async {
    AppLogger.info('Filtering reviews by verification: ${event.verifiedOnly}');
    
    _currentFilters = _currentFilters.copyWith(verifiedOnly: event.verifiedOnly);
    _applyFiltersAndSearch(emit);
  }

  Future<void> _onSortReviews(
    SortReviewsEvent event,
    Emitter<ReviewState> emit,
  ) async {
    AppLogger.info('Sorting reviews by: ${event.sortType.displayName}');
    
    _currentSortType = event.sortType;
    _applyFiltersAndSearch(emit);
  }

  Future<void> _onSearchReviews(
    SearchReviewsEvent event,
    Emitter<ReviewState> emit,
  ) async {
    AppLogger.info('Searching reviews with query: ${event.query}');
    
    _currentSearchQuery = event.query;
    _applyFiltersAndSearch(emit);
  }

  Future<void> _onLoadRecentReviews(
    LoadRecentReviewsEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading recent reviews (limit: ${event.limit})');
    
    emit(const ReviewsLoading());
    
    try {
      final recentReviews = await _reviewService.getRecentReviews(event.limit);
      
      stopwatch.stop();
      AppLogger.performance('Load Recent Reviews', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'getRecentReviews', true);
      
      emit(RecentReviewsLoaded(
        recentReviews: recentReviews,
        totalCount: recentReviews.length,
      ));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load recent reviews', e);
      AppLogger.serviceOperation('ReviewService', 'getRecentReviews', false);
      emit(ReviewError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onLoadTopReviews(
    LoadTopReviewsEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Loading top reviews for ${event.tourPlanId} (limit: ${event.limit})');
    
    emit(const ReviewsLoading());
    
    try {
      final topReviews = await _reviewService.getTopReviews(
        limit: event.limit,
      );
      
      stopwatch.stop();
      AppLogger.performance('Load Top Reviews', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'getTopReviews', true);
      
      emit(TopReviewsLoaded(
        topReviews: topReviews,
        tourPlanId: event.tourPlanId,
      ));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to load top reviews', e);
      AppLogger.serviceOperation('ReviewService', 'getTopReviews', false);
      emit(ReviewError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onCheckUserCanReview(
    CheckUserCanReviewEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Checking if user ${event.userId} can review tour plan ${event.tourPlanId}');
    
    try {
      final canReview = await _reviewService.canUserReview(
        event.userId,
        event.tourPlanId,
      );
      
      stopwatch.stop();
      AppLogger.performance('Check User Can Review', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'canUserReview', true);
      
      emit(UserCanReviewChecked(
        canReview: canReview,
        userId: event.userId,
        tourPlanId: event.tourPlanId,
        reason: canReview ? 'User can review this tour plan' : 'User has already reviewed this tour plan',
      ));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to check user review eligibility', e);
      AppLogger.serviceOperation('ReviewService', 'canUserReview', false);
      emit(ReviewError(message: _getErrorMessage(e)));
    }
  }

  Future<void> _onUploadReviewImages(
    UploadReviewImagesEvent event,
    Emitter<ReviewState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Uploading ${event.imagePaths.length} review images');
    
    emit(ReviewImageUploadLoading(
      uploadedCount: 0,
      totalCount: event.imagePaths.length,
    ));
    
    try {
      final imageUrls = await _reviewService.uploadReviewImages(event.imagePaths);
      
      stopwatch.stop();
      AppLogger.performance('Upload Review Images', stopwatch.elapsed);
      AppLogger.serviceOperation('ReviewService', 'uploadReviewImages', true);
      AppLogger.info('Review images uploaded successfully: ${imageUrls.length} images');
      
      emit(ReviewImagesUploaded(imageUrls: imageUrls));
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Failed to upload review images', e);
      AppLogger.serviceOperation('ReviewService', 'uploadReviewImages', false);
      emit(ReviewImageUploadError(
        message: _getErrorMessage(e),
        failedImages: event.imagePaths,
      ));
    }
  }

  Future<void> _onRefreshReviews(
    RefreshReviewsEvent event,
    Emitter<ReviewState> emit,
  ) async {
    AppLogger.info('Refreshing reviews');
    
    // Refresh based on current state
    if (state is ReviewsLoaded) {
      final currentState = state as ReviewsLoaded;
      switch (currentState.loadType) {
        case ReviewLoadType.tourPlan:
          if (currentState.entityId != null) {
            add(LoadTourPlanReviewsEvent(tourPlanId: currentState.entityId!));
          }
          break;
        case ReviewLoadType.user:
          if (currentState.entityId != null) {
            add(LoadUserReviewsEvent(userId: currentState.entityId!));
          }
          break;
        case ReviewLoadType.recent:
          add(const LoadRecentReviewsEvent());
          break;
        default:
          AppLogger.warning('Cannot refresh reviews for type: ${currentState.loadType}');
      }
    }
  }

  Future<void> _onClearReviewError(
    ClearReviewErrorEvent event,
    Emitter<ReviewState> emit,
  ) async {
    AppLogger.info('Clearing review error');
    emit(const ReviewInitial());
  }

  Future<void> _onResetReviewFilters(
    ResetReviewFiltersEvent event,
    Emitter<ReviewState> emit,
  ) async {
    AppLogger.info('Resetting review filters');
    
    _currentFilters = const ReviewFilters();
    _currentSortType = ReviewSortType.newest;
    _currentSearchQuery = '';
    
    if (_allReviews.isNotEmpty) {
      emit(ReviewsLoaded(
        reviews: _sortReviews(_allReviews, _currentSortType),
        loadType: ReviewLoadType.all,
      ));
    }
  }

  void _applyFiltersAndSearch(Emitter<ReviewState> emit) {
    if (_allReviews.isEmpty) {
      emit(NoReviewsFound(
        searchQuery: _currentSearchQuery,
        filters: _currentFilters.hasFilters ? _currentFilters : null,
      ));
      return;
    }
    
    List<Review> filteredReviews = _allReviews;
    
    // Apply filters
    if (_currentFilters.hasFilters) {
      filteredReviews = filteredReviews
          .where((review) => _currentFilters.matchesReview(review))
          .toList();
    }
    
    // Apply search
    if (_currentSearchQuery.isNotEmpty) {
      final query = _currentSearchQuery.toLowerCase();
      filteredReviews = filteredReviews.where((review) {
        return review.comment.toLowerCase().contains(query) ||
               review.userName.toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply sorting
    filteredReviews = _sortReviews(filteredReviews, _currentSortType);
    
    if (filteredReviews.isEmpty) {
      emit(NoReviewsFound(
        searchQuery: _currentSearchQuery,
        filters: _currentFilters.hasFilters ? _currentFilters : null,
      ));
    } else if (_currentSearchQuery.isNotEmpty) {
      emit(SearchReviewsLoaded(
        reviews: filteredReviews,
        allReviews: _allReviews,
        query: _currentSearchQuery,
      ));
    } else if (_currentSortType != ReviewSortType.newest) {
      emit(SortedReviewsLoaded(
        reviews: filteredReviews,
        allReviews: _allReviews,
        sortType: _currentSortType,
      ));
    } else {
      emit(FilteredReviewsLoaded(
        reviews: filteredReviews,
        allReviews: _allReviews,
        filters: _currentFilters,
      ));
    }
  }

  List<Review> _sortReviews(List<Review> reviews, ReviewSortType sortType) {
    final sortedReviews = List<Review>.from(reviews);
    
    switch (sortType) {
      case ReviewSortType.newest:
        sortedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ReviewSortType.oldest:
        sortedReviews.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ReviewSortType.highestRating:
        sortedReviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ReviewSortType.lowestRating:
        sortedReviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case ReviewSortType.mostHelpful:
        sortedReviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
        break;
    }
    
    return sortedReviews;
  }

  void _validateReviewData(int rating, String comment) {
    if (rating < 1 || rating > 5) {
      throw const ValidationException('Rating must be between 1 and 5 stars');
    }
    
    if (comment.trim().isEmpty) {
      throw const ValidationException('Comment is required');
    }
    
    if (comment.trim().length < 10) {
      throw const ValidationException('Comment must be at least 10 characters');
    }
    
    if (comment.trim().length > 500) {
      throw const ValidationException('Comment cannot exceed 500 characters');
    }
  }

  Map<String, String> _extractFieldErrors(String message) {
    final fieldErrors = <String, String>{};
    
    if (message.contains('Rating')) {
      fieldErrors['rating'] = message;
    } else if (message.contains('Comment')) {
      fieldErrors['comment'] = message;
    }
    
    return fieldErrors;
  }

  String _getErrorMessage(dynamic error) {
    if (error is ReviewException) {
      return error.message;
    } else if (error is DatabaseException) {
      return 'Database error: ${error.message}';
    } else if (error is AuthenticationException) {
      return 'Authentication error: ${error.message}';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Future<void> close() {
    AppLogger.info('ReviewBloc disposed');
    return super.close();
  }
}