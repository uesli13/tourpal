import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Review extends Equatable {
  final String id;
  final String tourPlanId;
  final String userId;
  final String userName;
  final String? userProfileImage;
  final int rating; // 1-5 stars
  final String comment;
  final List<String> imageUrls;
  final bool isVerifiedBooking;
  final int helpfulCount;
  final int reportCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Review({
    required this.id,
    required this.tourPlanId,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    required this.rating,
    required this.comment,
    required this.imageUrls,
    required this.isVerifiedBooking,
    required this.helpfulCount,
    required this.reportCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      tourPlanId: map['tourPlanId'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userProfileImage: map['userProfileImage'] as String?,
      rating: map['rating'] as int,
      comment: map['comment'] as String,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      isVerifiedBooking: map['isVerifiedBooking'] as bool? ?? false,
      helpfulCount: map['helpfulCount'] as int? ?? 0,
      reportCount: map['reportCount'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tourPlanId': tourPlanId,
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'rating': rating,
      'comment': comment,
      'imageUrls': imageUrls,
      'isVerifiedBooking': isVerifiedBooking,
      'helpfulCount': helpfulCount,
      'reportCount': reportCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Review copyWith({
    int? rating,
    String? comment,
    List<String>? imageUrls,
    bool? isVerifiedBooking,
    int? helpfulCount,
    int? reportCount,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id,
      tourPlanId: tourPlanId,
      userId: userId,
      userName: userName,
      userProfileImage: userProfileImage,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      isVerifiedBooking: isVerifiedBooking ?? this.isVerifiedBooking,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      reportCount: reportCount ?? this.reportCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasImages => imageUrls.isNotEmpty;
  
  bool get hasUserImage => userProfileImage != null && userProfileImage!.isNotEmpty;
  
  bool get isPositiveReview => rating >= 4;
  
  bool get isNegativeReview => rating <= 2;
  
  bool get isNeutralReview => rating == 3;
  
  bool get isHelpful => helpfulCount > 0;
  
  bool get isReported => reportCount > 0;
  
  bool get isHighlyReported => reportCount >= 3;
  
  String get ratingDisplay {
    return '⭐' * rating + '☆' * (5 - rating);
  }
  
  String get ratingText {
    switch (rating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Very Good';
      case 3:
        return 'Good';
      case 2:
        return 'Fair';
      case 1:
        return 'Poor';
      default:
        return 'Unknown';
    }
  }
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years} year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months} month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
  
  String get helpfulDisplay {
    if (helpfulCount == 0) return '';
    if (helpfulCount == 1) return '1 person found this helpful';
    return '$helpfulCount people found this helpful';
  }
  
  String get verificationBadge {
    return isVerifiedBooking ? '✅ Verified booking' : '';
  }
  
  String get commentPreview {
    if (comment.length <= 100) return comment;
    return '${comment.substring(0, 100)}...';
  }
  
  bool get isRecent => DateTime.now().difference(createdAt).inDays <= 7;
  
  bool get isEdited => updatedAt.isAfter(createdAt.add(const Duration(minutes: 5)));

  bool get isValidRating => rating >= 1 && rating <= 5;
  
  bool get hasValidComment => comment.trim().isNotEmpty && comment.trim().length >= 10;
  
  bool get isValidForSubmission => isValidRating && hasValidComment;
  
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (!isValidRating) {
      errors.add('Rating must be between 1 and 5 stars');
    }
    
    if (comment.trim().isEmpty) {
      errors.add('Comment is required');
    } else if (comment.trim().length < 10) {
      errors.add('Comment must be at least 10 characters');
    } else if (comment.trim().length > 500) {
      errors.add('Comment cannot exceed 500 characters');
    }
    
    return errors;
  }

  bool matchesRatingFilter(List<int> ratingFilters) {
    if (ratingFilters.isEmpty) return true;
    return ratingFilters.contains(rating);
  }
  
  bool matchesVerificationFilter(bool? verifiedOnly) {
    if (verifiedOnly == null) return true;
    return verifiedOnly ? isVerifiedBooking : true;
  }
  
  bool containsKeyword(String keyword) {
    if (keyword.isEmpty) return true;
    final lowercaseKeyword = keyword.toLowerCase();
    return comment.toLowerCase().contains(lowercaseKeyword) ||
           userName.toLowerCase().contains(lowercaseKeyword);
  }
  
  double getHelpfulnessScore() {
    // Calculate helpfulness based on various factors
    double score = 0.0;
    
    // Base score from helpful votes
    score += helpfulCount * 2.0;
    
    // Penalty for reports
    score -= reportCount * 5.0;
    
    // Bonus for verified bookings
    if (isVerifiedBooking) score += 10.0;
    
    // Bonus for detailed comments
    if (comment.length > 100) score += 3.0;
    
    // Bonus for images
    score += imageUrls.length * 2.0;
    
    // Recent reviews get slight boost
    if (isRecent) score += 1.0;
    
    return score.clamp(0.0, double.infinity);
  }

  String get sentimentIndicator {
    final lowerComment = comment.toLowerCase();
    
    // Positive indicators
    final positiveWords = ['excellent', 'amazing', 'fantastic', 'wonderful', 
                          'great', 'awesome', 'perfect', 'loved', 'recommend'];
    final positiveCount = positiveWords.where((word) => lowerComment.contains(word)).length;
    
    // Negative indicators
    final negativeWords = ['terrible', 'awful', 'horrible', 'disappointing', 
                          'waste', 'bad', 'worst', 'regret', 'avoid'];
    final negativeCount = negativeWords.where((word) => lowerComment.contains(word)).length;
    
    if (positiveCount > negativeCount && rating >= 4) return '😊 Positive';
    if (negativeCount > positiveCount && rating <= 2) return '😞 Negative';
    return '😐 Neutral';
  }

  ReviewQuality get quality {
    int qualityScore = 0;
    
    // Rating consistency with comment sentiment
    if ((rating >= 4 && comment.toLowerCase().contains(RegExp(r'great|good|excellent|amazing'))) ||
        (rating <= 2 && comment.toLowerCase().contains(RegExp(r'bad|terrible|awful|disappointing')))) {
      qualityScore += 2;
    }
    
    // Comment length
    if (comment.length >= 50) qualityScore += 1;
    if (comment.length >= 150) qualityScore += 1;
    
    // Images provided
    qualityScore += imageUrls.length.clamp(0, 2);
    
    // Verified booking
    if (isVerifiedBooking) qualityScore += 2;
    
    // Low reports
    if (reportCount == 0) qualityScore += 1;
    
    if (qualityScore >= 7) return ReviewQuality.excellent;
    if (qualityScore >= 5) return ReviewQuality.good;
    if (qualityScore >= 3) return ReviewQuality.average;
    return ReviewQuality.poor;
  }

  @override
  List<Object?> get props => [
    id,
    tourPlanId,
    userId,
    userName,
    userProfileImage,
    rating,
    comment,
    imageUrls,
    isVerifiedBooking,
    helpfulCount,
    reportCount,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'Review{id: $id, tourPlanId: $tourPlanId, userId: $userId, '
           'rating: $rating, isVerified: $isVerifiedBooking, '
           'helpfulCount: $helpfulCount, timeAgo: $timeAgo}';
  }
}

enum ReviewQuality {
  excellent,
  good,
  average,
  poor,
}

extension ReviewQualityExtension on ReviewQuality {
  String get displayName {
    switch (this) {
      case ReviewQuality.excellent:
        return '🌟 Excellent Review';
      case ReviewQuality.good:
        return '👍 Good Review';
      case ReviewQuality.average:
        return '👌 Average Review';
      case ReviewQuality.poor:
        return '👎 Poor Review';
    }
  }
  
  String get description {
    switch (this) {
      case ReviewQuality.excellent:
        return 'Detailed, verified, and helpful review';
      case ReviewQuality.good:
        return 'Good quality review with useful information';
      case ReviewQuality.average:
        return 'Basic review with minimal details';
      case ReviewQuality.poor:
        return 'Limited information or potentially unreliable';
    }
  }
}