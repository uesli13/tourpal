import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../core/utils/logger.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  
  ReviewService({
    FirebaseFirestore? firestore,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  Future<List<Review>> getReviewsByTourPlan(String tourPlanId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.review('Getting reviews by tour plan', tourPlanId);

    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('tourPlanId', isEqualTo: tourPlanId)
          .orderBy('createdAt', descending: true)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => Review.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      AppLogger.performance('Get Reviews By Tour Plan', stopwatch.elapsed);
      AppLogger.review('Reviews retrieved successfully', '${reviews.length} reviews for $tourPlanId');

      return reviews;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting reviews by tour plan', e);
      throw DatabaseException('Failed to get reviews: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error getting reviews by tour plan', e);
      throw const ReviewServiceException('Failed to retrieve reviews');
    }
  }

  Future<List<Review>> getReviewsByUser(String userId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.review('Getting reviews by user', userId);

    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => Review.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      AppLogger.performance('Get Reviews By User', stopwatch.elapsed);
      AppLogger.review('User reviews retrieved successfully', '${reviews.length} reviews for $userId');

      return reviews;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting reviews by user', e);
      throw DatabaseException('Failed to get user reviews: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error getting reviews by user', e);
      throw const ReviewServiceException('Failed to retrieve user reviews');
    }
  }

  Future<Review> getReviewById(String reviewId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.review('Getting review by ID', reviewId);

    try {
      final docSnapshot = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .get();

      if (!docSnapshot.exists) {
        throw const ReviewException('Review not found');
      }

      final review = Review.fromMap(docSnapshot.data()!, reviewId);

      stopwatch.stop();
      AppLogger.performance('Get Review By ID', stopwatch.elapsed);
      AppLogger.review('Review retrieved successfully', reviewId);

      return review;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting review by ID', e);
      throw DatabaseException('Failed to get review: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error getting review by ID', e);
      throw const ReviewServiceException('Failed to retrieve review');
    }
  }

  Future<Review> createReview({
    required String tourPlanId,
    required int rating,
    required String comment,
    List<String>? imageUrls,
  }) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.review('Creating review for tour plan', tourPlanId);

    try {
      // Validate review data
      _validateReviewData(rating, comment);

      // Check if user has already reviewed this tour plan
      final existingReview = await _getUserReviewForTourPlan(currentUser.uid, tourPlanId);
      if (existingReview != null) {
        throw const ReviewException('You have already reviewed this tour plan');
      }

      // Create review document
      final reviewData = {
        'tourPlanId': tourPlanId,
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous',
        'userProfileImage': currentUser.photoURL ?? '',
        'rating': rating,
        'comment': comment.trim(),
        'imageUrls': imageUrls ?? <String>[],
        'isVerifiedBooking': false, // Can be updated later if user has booking
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'helpfulCount': 0,
        'reportCount': 0,
      };

      final docRef = await _firestore
          .collection('reviews')
          .add(reviewData);

      // Update tour plan's average rating and review count
      await _updateTourPlanRatingStats(tourPlanId);

      // Get the created review
      final createdDoc = await docRef.get();
      final review = Review.fromMap(createdDoc.data()!, docRef.id);

      stopwatch.stop();
      AppLogger.performance('Create Review', stopwatch.elapsed);
      AppLogger.review('Review created successfully', review.id);

      return review;

    } on ValidationException catch (e) {
      AppLogger.warning('Validation error during review creation: ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error creating review', e);
      throw ReviewServiceException('Failed to create review: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error creating review', e);
      throw const ReviewServiceException('Failed to create review');
    }
  }

  Future<Review> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
    List<String>? imageUrls,
  }) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.review('Updating review', reviewId);

    try {
      // Verify review ownership
      await _verifyReviewOwnership(reviewId, currentUser.uid);

      // Validate inputs if provided
      if (rating != null || comment != null) {
        _validateReviewUpdateData(rating, comment);
      }

      // Build update data
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (rating != null) updateData['rating'] = rating;
      if (comment != null) updateData['comment'] = comment.trim();
      if (imageUrls != null) updateData['imageUrls'] = imageUrls;

      // Update review document
      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .update(updateData);

      // Update tour plan's rating stats if rating changed
      if (rating != null) {
        final reviewDoc = await _firestore
            .collection('reviews')
            .doc(reviewId)
            .get();
        final tourPlanId = reviewDoc.data()!['tourPlanId'] as String;
        await _updateTourPlanRatingStats(tourPlanId);
      }

      // Get updated review
      final updatedDoc = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .get();

      final review = Review.fromMap(updatedDoc.data()!, reviewId);

      stopwatch.stop();
      AppLogger.performance('Update Review', stopwatch.elapsed);
      AppLogger.review('Review updated successfully', reviewId);

      return review;

    } on ValidationException catch (e) {
      AppLogger.warning('Validation error during review update: ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error updating review', e);
      throw ReviewServiceException('Failed to update review: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error updating review', e);
      throw const ReviewServiceException('Failed to update review');
    }
  }

  Future<void> deleteReview(String reviewId) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.review('Deleting review', reviewId);

    try {
      // Get review data before deletion for tour plan update
      final reviewDoc = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .get();

      if (!reviewDoc.exists) {
        throw const ReviewException('Review not found');
      }

      final reviewData = reviewDoc.data()!;
      final tourPlanId = reviewData['tourPlanId'] as String;

      // Verify review ownership
      await _verifyReviewOwnership(reviewId, currentUser.uid);

      // Delete review document
      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .delete();

      // Update tour plan's rating stats
      await _updateTourPlanRatingStats(tourPlanId);

      stopwatch.stop();
      AppLogger.performance('Delete Review', stopwatch.elapsed);
      AppLogger.review('Review deleted successfully', reviewId);

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error deleting review', e);
      throw ReviewServiceException('Failed to delete review: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error deleting review', e);
      throw const ReviewServiceException('Failed to delete review');
    }
  }

  Future<void> markReviewAsHelpful(String reviewId) async {
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.review('Marking review as helpful', reviewId);

    try {
      // Check if user has already marked this review as helpful
      final helpfulDoc = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .collection('helpful')
          .doc(currentUser.uid)
          .get();

      if (helpfulDoc.exists) {
        throw const ReviewException('You have already marked this review as helpful');
      }

      // Add helpful document and increment count
      final batch = _firestore.batch();
      
      batch.set(
        _firestore
            .collection('reviews')
            .doc(reviewId)
            .collection('helpful')
            .doc(currentUser.uid),
        {
          'userId': currentUser.uid,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        _firestore.collection('reviews').doc(reviewId),
        {'helpfulCount': FieldValue.increment(1)},
      );

      await batch.commit();

      AppLogger.review('Review marked as helpful successfully', reviewId);

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error marking review as helpful', e);
      throw ReviewServiceException('Failed to mark review as helpful: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error marking review as helpful', e);
      throw const ReviewServiceException('Failed to mark review as helpful');
    }
  }

  Future<void> reportReview({
    required String reviewId,
    required String reason,
    String? details,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.review('Reporting review', reviewId);

    try {
      // Check if user has already reported this review
      final reportDoc = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .collection('reports')
          .doc(currentUser.uid)
          .get();

      if (reportDoc.exists) {
        throw const ReviewException('You have already reported this review');
      }

      // Add report document and increment count
      final batch = _firestore.batch();
      
      batch.set(
        _firestore
            .collection('reviews')
            .doc(reviewId)
            .collection('reports')
            .doc(currentUser.uid),
        {
          'userId': currentUser.uid,
          'reason': reason,
          'details': details ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        _firestore.collection('reviews').doc(reviewId),
        {'reportCount': FieldValue.increment(1)},
      );

      await batch.commit();

      AppLogger.review('Review reported successfully', reviewId);

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error reporting review', e);
      throw ReviewServiceException('Failed to report review: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error reporting review', e);
      throw const ReviewServiceException('Failed to report review');
    }
  }

  Future<Map<String, dynamic>> getTourPlanRatingStats(String tourPlanId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.review('Getting rating stats for tour plan', tourPlanId);

    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('tourPlanId', isEqualTo: tourPlanId)
          .get();

      final reviews = querySnapshot.docs;
      
      if (reviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      final ratings = reviews.map((doc) => doc.data()['rating'] as int).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;

      final ratingDistribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final rating in ratings) {
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
      }

      final stats = {
        'averageRating': averageRating,
        'totalReviews': reviews.length,
        'ratingDistribution': ratingDistribution,
      };

      stopwatch.stop();
      AppLogger.performance('Get Tour Plan Rating Stats', stopwatch.elapsed);
      AppLogger.review('Rating stats retrieved successfully', tourPlanId);

      return stats;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting rating stats', e);
      throw DatabaseException('Failed to get rating stats: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error getting rating stats', e);
      throw const ReviewServiceException('Failed to retrieve rating stats');
    }
  }

  Future<Review?> _getUserReviewForTourPlan(String userId, String tourPlanId) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('tourPlanId', isEqualTo: tourPlanId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      return Review.fromMap(doc.data(), doc.id);

    } catch (e) {
      AppLogger.error('Error checking existing user review', e);
      return null;
    }
  }

  Future<void> _verifyReviewOwnership(String reviewId, String userId) async {
    final reviewDoc = await _firestore
        .collection('reviews')
        .doc(reviewId)
        .get();

    if (!reviewDoc.exists) {
      throw const ReviewException('Review not found');
    }

    final reviewData = reviewDoc.data()!;
    if (reviewData['userId'] != userId) {
      throw const ReviewException('You do not have permission to modify this review');
    }
  }

  Future<void> _updateTourPlanRatingStats(String tourPlanId) async {
    try {
      final stats = await getTourPlanRatingStats(tourPlanId);
      
      await _firestore
          .collection('tourPlans')
          .doc(tourPlanId)
          .update({
            'averageRating': stats['averageRating'],
            'totalReviews': stats['totalReviews'],
            'updatedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.firebase('Tour plan rating stats updated', tourPlanId);

    } catch (e) {
      AppLogger.error('Error updating tour plan rating stats', e);
      // Don't throw here to avoid breaking review operations
    }
  }

  void _validateReviewData(int rating, String comment) {
    if (rating < 1 || rating > 5) {
      throw const ReviewValidationException('Rating must be between 1 and 5');
    }
    if (comment.trim().isEmpty) {
      throw const ReviewValidationException('Comment cannot be empty');
    }
    if (comment.trim().length < 10) {
      throw const ReviewValidationException('Comment must be at least 10 characters');
    }
    if (comment.trim().length > 500) {
      throw const ReviewValidationException('Comment cannot exceed 500 characters');
    }
  }

  void _validateReviewUpdateData(int? rating, String? comment) {
    if (rating != null) {
      if (rating < 1 || rating > 5) {
        throw const ReviewValidationException('Rating must be between 1 and 5');
      }
    }
    if (comment != null) {
      if (comment.trim().isEmpty) {
        throw const ReviewValidationException('Comment cannot be empty');
      }
      if (comment.trim().length < 10) {
        throw const ReviewValidationException('Comment must be at least 10 characters');
      }
      if (comment.trim().length > 500) {
        throw const ReviewValidationException('Comment cannot exceed 500 characters');
      }
    }
  }

  /// Mark review as helpful and return updated review
  Future<Review> markReviewHelpful(String reviewId) async {
    await markReviewAsHelpful(reviewId);
    return await getReviewById(reviewId);
  }

  /// Get recent reviews across all tour plans
  Future<List<Review>> getRecentReviews(int limit) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.review('Getting recent reviews', 'limit: $limit');

    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => Review.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      AppLogger.performance('Get Recent Reviews', stopwatch.elapsed);
      AppLogger.review('Recent reviews retrieved', '${reviews.length} reviews');

      return reviews;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting recent reviews', e);
      throw DatabaseException('Failed to get recent reviews: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error getting recent reviews', e);
      throw const ReviewServiceException('Failed to retrieve recent reviews');
    }
  }

  /// Get top-rated reviews
  Future<List<Review>> getTopReviews({
    required int limit,
    int? minRating,
  }) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.review('Getting top reviews', 'limit: $limit, minRating: $minRating');

    try {
      Query<Map<String, dynamic>> query = _firestore.collection('reviews');
      
      if (minRating != null) {
        query = query.where('rating', isGreaterThanOrEqualTo: minRating);
      }
      
      final querySnapshot = await query
          .orderBy('rating', descending: true)
          .orderBy('helpfulCount', descending: true)
          .limit(limit)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => Review.fromMap(doc.data(), doc.id))
          .toList();

      stopwatch.stop();
      AppLogger.performance('Get Top Reviews', stopwatch.elapsed);
      AppLogger.review('Top reviews retrieved', '${reviews.length} reviews');

      return reviews;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting top reviews', e);
      throw DatabaseException('Failed to get top reviews: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error getting top reviews', e);
      throw const ReviewServiceException('Failed to retrieve top reviews');
    }
  }

  /// Check if user can review a tour plan
  Future<bool> canUserReview(String userId, String tourPlanId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.review('Checking if user can review', 'user: $userId, tour: $tourPlanId');

    try {
      // Check if user has already reviewed this tour plan
      final existingReview = await _getUserReviewForTourPlan(userId, tourPlanId);
      final canReview = existingReview == null;

      stopwatch.stop();
      AppLogger.performance('Check Can User Review', stopwatch.elapsed);
      AppLogger.review('User review eligibility checked', 'canReview: $canReview');

      return canReview;

    } catch (e) {
      AppLogger.error('Error checking user review eligibility', e);
      return false;
    }
  }

  /// Upload review images
  Future<List<String>> uploadReviewImages(List<String> imagePaths) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.review('Uploading review images', '${imagePaths.length} images');

    try {
      // For now, return placeholder URLs
      // In a real implementation, this would upload to Firebase Storage
      final imageUrls = imagePaths.map((path) => 
          'https://placeholder.com/review-image-${DateTime.now().millisecondsSinceEpoch}.jpg'
      ).toList();

      stopwatch.stop();
      AppLogger.performance('Upload Review Images', stopwatch.elapsed);
      AppLogger.review('Review images uploaded', '${imageUrls.length} images');

      return imageUrls;

    } catch (e) {
      AppLogger.error('Error uploading review images', e);
      throw const ReviewServiceException('Failed to upload review images');
    }
  }
}