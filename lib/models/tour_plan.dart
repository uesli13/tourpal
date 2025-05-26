import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/tours/domain/enums/tour_status.dart';

class TourPlan extends Equatable {
  final String id;
  final String guideId;
  final String title;
  final String description;
  final int duration; // in hours
  final String difficulty; // easy, medium, hard
  final List<String> tags;
  final bool isPublic;
  final TourStatus status; // NEW: Track tour status (draft, published, etc.)
  final double averageRating;
  final int totalReviews;
  final int bookingCount;
  final int favoriteCount;
  final double? price; // optional pricing
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TourPlan({
    required this.id,
    required this.guideId,
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.tags,
    required this.isPublic,
    this.status = TourStatus.draft, // Default to draft
    required this.averageRating,
    required this.totalReviews,
    required this.bookingCount,
    required this.favoriteCount,
    this.price,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TourPlan.fromMap(Map<String, dynamic> map, String id) {
    return TourPlan(
      id: id,
      guideId: map['guideId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      duration: map['duration'] as int,
      difficulty: map['difficulty'] as String,
      tags: List<String>.from(map['tags'] ?? []),
      isPublic: map['isPublic'] as bool? ?? false,
      status: TourStatus.fromString(map['status'] as String? ?? 'draft'),
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: map['totalReviews'] as int? ?? 0,
      bookingCount: map['bookingCount'] as int? ?? 0,
      favoriteCount: map['favoriteCount'] as int? ?? 0,
      price: (map['price'] as num?)?.toDouble(),
      imageUrl: map['imageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guideId': guideId,
      'title': title,
      'description': description,
      'duration': duration,
      'difficulty': difficulty,
      'tags': tags,
      'isPublic': isPublic,
      'status': status.value,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'bookingCount': bookingCount,
      'favoriteCount': favoriteCount,
      'price': price,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TourPlan copyWith({
    String? title,
    String? description,
    int? duration,
    String? difficulty,
    List<String>? tags,
    bool? isPublic,
    TourStatus? status,
    double? averageRating,
    int? totalReviews,
    int? bookingCount,
    int? favoriteCount,
    double? price,
    String? imageUrl,
    DateTime? updatedAt,
  }) {
    return TourPlan(
      id: id,
      guideId: guideId,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      status: status ?? this.status,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      bookingCount: bookingCount ?? this.bookingCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasRatings => totalReviews > 0;
  
  bool get isPaid => price != null && price! > 0;
  
  bool get isFree => price == null || price! == 0;
  
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  
  String get difficultyDisplay {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return '🟢 Easy';
      case 'medium':
        return '🟡 Medium';
      case 'hard':
        return '🔴 Hard';
      default:
        return '⚪ Unknown';
    }
  }
  
  String get durationDisplay {
    if (duration == 1) return '1 hour';
    if (duration < 24) return '$duration hours';
    final days = (duration / 24).floor();
    final hours = duration % 24;
    if (hours == 0) return '$days day${days > 1 ? 's' : ''}';
    return '$days day${days > 1 ? 's' : ''} ${hours}h';
  }
  
  String get ratingDisplay {
    if (totalReviews == 0) return 'No ratings yet';
    return '${averageRating.toStringAsFixed(1)} ⭐ (${totalReviews} reviews)';
  }
  
  String get priceDisplay {
    if (price == null || price! == 0) return 'Free';
    return '\$${price!.toStringAsFixed(0)}';
  }
  
  String get popularityLevel {
    if (bookingCount >= 100) return 'Very Popular';
    if (bookingCount >= 50) return 'Popular';
    if (bookingCount >= 10) return 'Rising';
    return 'New';
  }
  
  bool get isHighlyRated => averageRating >= 4.5 && totalReviews >= 5;
  
  bool get isPopular => bookingCount >= 20 || favoriteCount >= 10;
  
  bool get isNewTour => DateTime.now().difference(createdAt).inDays <= 30;
  
  String get statusDisplay {
    return '${status.icon} ${status.displayName}';
  }
  
  bool get isDraft => status.isDraft;
  bool get isPublished => status.isPublished;
  
  bool get canBePublished => isValidForPublication && status.isDraft;
  bool get canBeSavedAsDraft => !status.isDraft;

  List<String> get hashtags => tags.map((tag) => '#$tag').toList();

  double getSearchRelevance(String query) {
    if (query.isEmpty) return 0.0;
    
    final lowercaseQuery = query.toLowerCase();
    double score = 0.0;
    
    // Title match (highest weight)
    if (title.toLowerCase().contains(lowercaseQuery)) {
      score += 10.0;
      if (title.toLowerCase().startsWith(lowercaseQuery)) {
        score += 5.0; // Boost for prefix match
      }
    }
    
    // Description match (medium weight)
    if (description.toLowerCase().contains(lowercaseQuery)) {
      score += 5.0;
    }
    
    // Tags match (medium weight)
    for (final tag in tags) {
      if (tag.toLowerCase().contains(lowercaseQuery)) {
        score += 3.0;
      }
    }
    
    // Difficulty match (low weight)
    if (difficulty.toLowerCase().contains(lowercaseQuery)) {
      score += 2.0;
    }
    
    // Boost for popular tours
    if (isPopular) score *= 1.2;
    if (isHighlyRated) score *= 1.1;
    
    return score;
  }

  bool get isValidForPublication {
    return title.trim().isNotEmpty &&
           description.trim().isNotEmpty &&
           duration > 0 &&
           ['easy', 'medium', 'hard'].contains(difficulty.toLowerCase()) &&
           tags.isNotEmpty;
  }
  
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (title.trim().isEmpty) {
      errors.add('Title is required');
    } else if (title.trim().length > 100) {
      errors.add('Title cannot exceed 100 characters');
    }
    
    if (description.trim().isEmpty) {
      errors.add('Description is required');
    } else if (description.trim().length > 500) {
      errors.add('Description cannot exceed 500 characters');
    }
    
    if (duration <= 0) {
      errors.add('Duration must be greater than 0');
    } else if (duration > 24) {
      errors.add('Duration cannot exceed 24 hours');
    }
    
    if (!['easy', 'medium', 'hard'].contains(difficulty.toLowerCase())) {
      errors.add('Invalid difficulty level');
    }
    
    if (tags.isEmpty) {
      errors.add('At least one tag is required');
    }
    
    if (price != null && price! < 0) {
      errors.add('Price cannot be negative');
    }
    
    return errors;
  }

  @override
  List<Object?> get props => [
    id,
    guideId,
    title,
    description,
    duration,
    difficulty,
    tags,
    isPublic,
    status,
    averageRating,
    totalReviews,
    bookingCount,
    favoriteCount,
    price,
    imageUrl,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'TourPlan{id: $id, title: $title, difficulty: $difficulty, '
           'duration: $duration, isPublic: $isPublic, averageRating: $averageRating, '
           'bookingCount: $bookingCount}';
  }
}