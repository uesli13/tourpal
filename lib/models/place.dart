import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

enum PlaceCategory {
  restaurant,
  museum,
  park,
  beach,
  mountain,
  historical,
  shopping,
  entertainment,
  nature,
  cultural,
  adventure,
  relaxation,
  nightlife,
  sports,
  religious,
  educational,
  other;

  String get displayName {
    switch (this) {
      case PlaceCategory.restaurant:
        return '🍽️ Restaurant';
      case PlaceCategory.museum:
        return '🏛️ Museum';
      case PlaceCategory.park:
        return '🌳 Park';
      case PlaceCategory.beach:
        return '🏖️ Beach';
      case PlaceCategory.mountain:
        return '⛰️ Mountain';
      case PlaceCategory.historical:
        return '🏰 Historical';
      case PlaceCategory.shopping:
        return '🛍️ Shopping';
      case PlaceCategory.entertainment:
        return '🎭 Entertainment';
      case PlaceCategory.nature:
        return '🌿 Nature';
      case PlaceCategory.cultural:
        return '🎨 Cultural';
      case PlaceCategory.adventure:
        return '🏔️ Adventure';
      case PlaceCategory.relaxation:
        return '🧘 Relaxation';
      case PlaceCategory.nightlife:
        return '🌃 Nightlife';
      case PlaceCategory.sports:
        return '⚽ Sports';
      case PlaceCategory.religious:
        return '⛪ Religious';
      case PlaceCategory.educational:
        return '📚 Educational';
      case PlaceCategory.other:
        return '📍 Other';
    }
  }

  String get name => displayName;
}

enum PlaceSortType {
  name,
  distance,
  popularity,
  rating,
  newest,
  oldest;

  String get displayName {
    switch (this) {
      case PlaceSortType.name:
        return 'Name';
      case PlaceSortType.distance:
        return 'Distance';
      case PlaceSortType.popularity:
        return 'Popularity';
      case PlaceSortType.rating:
        return 'Rating';
      case PlaceSortType.newest:
        return 'Newest';
      case PlaceSortType.oldest:
        return 'Oldest';
    }
  }
}

class PlaceFilters {
  final Set<PlaceCategory> categories;
  final double? minRating;
  final double? maxDistance;
  final double? minPrice;
  final double? maxPrice;
  final bool? isOpen;

  const PlaceFilters({
    this.categories = const {},
    this.minRating,
    this.maxDistance,
    this.minPrice,
    this.maxPrice,
    this.isOpen,
  });

  PlaceFilters copyWith({
    Set<PlaceCategory>? categories,
    double? minRating,
    double? maxDistance,
    double? minPrice,
    double? maxPrice,
    bool? isOpen,
  }) {
    return PlaceFilters(
      categories: categories ?? this.categories,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}

class PlaceRecommendations {
  final List<Place> places;
  final String reason;
  final double confidence;

  const PlaceRecommendations({
    required this.places,
    required this.reason,
    this.confidence = 0.0,
  });
}

class Place {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> imageUrls;
  final PlaceCategory category;
  final double averageRating;
  final int reviewCount;
  final int visitCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final bool isActive;
  final String? createdBy;

  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.imageUrls,
    required this.category,
    required this.averageRating,
    required this.reviewCount,
    required this.visitCount,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    required this.metadata,
    required this.isActive,
    this.createdBy,
  });

  factory Place.fromMap(Map<String, dynamic> map, String id) {
    return Place(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      category: PlaceCategory.values.firstWhere(
          (e) => e.toString() == 'PlaceCategory.${map['category']}',
          orElse: () => PlaceCategory.other),
      averageRating: (map['averageRating'] as num).toDouble(),
      reviewCount: map['reviewCount'] as int? ?? 0,
      visitCount: map['visitCount'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      tags: List<String>.from(map['tags'] ?? []),
      metadata: map['metadata'] as Map<String, dynamic>? ?? {},
      isActive: map['isActive'] as bool? ?? true,
      createdBy: map['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'imageUrls': imageUrls,
      'category': category.toString().split('.').last,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'visitCount': visitCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'tags': tags,
      'metadata': metadata,
      'isActive': isActive,
      'createdBy': createdBy,
    };
  }

  Place copyWith({
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? imageUrls,
    PlaceCategory? category,
    double? averageRating,
    int? reviewCount,
    int? visitCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool? isActive,
    String? createdBy,
  }) {
    return Place(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      visitCount: visitCount ?? this.visitCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  bool get hasImage => imageUrls.isNotEmpty;
  
  bool get hasCategories => category != PlaceCategory.other;
  
  String get visitDurationDisplay {
    if (visitCount < 60) return '${visitCount}min';
    final hours = visitCount ~/ 60;
    final minutes = visitCount % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}min';
  }
  
  String get primaryCategory => category.toString().split('.').last;
  
  String get categoriesDisplay => tags.join(', ');
  
  String get coordinatesDisplay => '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  
  double distanceToKm(double otherLatitude, double otherLongitude) {
    return calculateDistance(otherLatitude, otherLongitude);
  }
  
  /// Calculate distance between this place and given coordinates using Haversine formula
  double calculateDistance(double otherLatitude, double otherLongitude) {
    const double earthRadiusKm = 6371.0;
    
    final double dLat = _degreesToRadians(otherLatitude - latitude);
    final double dLng = _degreesToRadians(otherLongitude - longitude);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(latitude)) * math.cos(_degreesToRadians(otherLatitude)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadiusKm * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
  
  String distanceToDisplay(double otherLatitude, double otherLongitude) {
    final distance = distanceToKm(otherLatitude, otherLongitude);
    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    }
    return '${distance.toStringAsFixed(1)}km away';
  }

  bool get isValidLocation => 
      latitude >= -90 && latitude <= 90 && 
      longitude >= -180 && longitude <= 180;
  
  bool get isValidForTour => 
      name.trim().isNotEmpty &&
      description.trim().isNotEmpty &&
      address.trim().isNotEmpty &&
      isValidLocation &&
      visitCount > 0;
  
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (name.trim().isEmpty) {
      errors.add('Place name is required');
    } else if (name.trim().length > 100) {
      errors.add('Place name cannot exceed 100 characters');
    }
    
    if (description.trim().isEmpty) {
      errors.add('Place description is required');
    } else if (description.trim().length > 300) {
      errors.add('Place description cannot exceed 300 characters');
    }
    
    if (address.trim().isEmpty) {
      errors.add('Address is required');
    } else if (address.trim().length > 200) {
      errors.add('Address cannot exceed 200 characters');
    }
    
    if (!isValidLocation) {
      errors.add('Invalid coordinates');
    }
    
    if (visitCount <= 0) {
      errors.add('Visit duration must be greater than 0');
    } else if (visitCount > 480) { // 8 hours max
      errors.add('Visit duration cannot exceed 8 hours');
    }
    
    return errors;
  }

  double getSearchRelevance(String query) {
    if (query.isEmpty) return 0.0;
    
    final lowercaseQuery = query.toLowerCase();
    double score = 0.0;
    
    // Name match (highest weight)
    if (name.toLowerCase().contains(lowercaseQuery)) {
      score += 10.0;
      if (name.toLowerCase().startsWith(lowercaseQuery)) {
        score += 5.0; // Boost for prefix match
      }
    }
    
    // Address match (high weight)
    if (address.toLowerCase().contains(lowercaseQuery)) {
      score += 8.0;
    }
    
    // Description match (medium weight)
    if (description.toLowerCase().contains(lowercaseQuery)) {
      score += 5.0;
    }
    
    // Category match (medium weight)
    for (final tag in tags) {
      if (tag.toLowerCase().contains(lowercaseQuery)) {
        score += 4.0;
      }
    }
    
    return score;
  }

  bool matchesCategory(String categoryFilter) {
    if (categoryFilter.isEmpty) return true;
    return tags.any((cat) => 
        cat.toLowerCase().contains(categoryFilter.toLowerCase()));
  }
  
  bool isInCategories(List<String> categoryFilters) {
    if (categoryFilters.isEmpty) return true;
    return categoryFilters.any((filter) => matchesCategory(filter));
  }

  List<Object?> get props => [
    id,
    name,
    description,
    latitude,
    longitude,
    address,
    imageUrls,
    category,
    averageRating,
    reviewCount,
    visitCount,
    createdAt,
    updatedAt,
    tags,
    metadata,
    isActive,
    createdBy,
  ];

  @override
  String toString() {
    return 'Place{id: $id, name: $name, address: $address, '
           'coordinates: ($latitude, $longitude), category: $category, '
           'visitDuration: ${visitCount}min}';
  }
}