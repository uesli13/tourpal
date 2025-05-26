import '../enums/tour_category.dart';
import '../enums/tour_difficulty.dart';

class TourLocation {
  final String id;
  final double latitude;
  final double longitude;
  final String address;
  final String? name;

  const TourLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.name,
  });

  factory TourLocation.fromJson(Map<String, dynamic> json) {
    return TourLocation(
      id: json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TourLocation &&
        other.id == id &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.address == address &&
        other.name == name;
  }

  @override
  int get hashCode {
    return Object.hash(id, latitude, longitude, address, name);
  }

  @override
  String toString() {
    return 'TourLocation(id: $id, latitude: $latitude, longitude: $longitude, address: $address, name: $name)';
  }

  /// Simple address search - search for any string within the address
  bool containsSearch(String searchQuery) {
    if (searchQuery.trim().isEmpty) return true;

    final query = searchQuery.toLowerCase().trim();
    return address.toLowerCase().contains(query) ||
        (name?.toLowerCase().contains(query) ?? false);
  }

  /// Validation getter for tour request models
  bool get isValid {
    // Validate required fields
    if (id.trim().isEmpty) return false;
    if (address.trim().isEmpty) return false;

    // Validate latitude range (-90 to 90)
    if (latitude < -90.0 || latitude > 90.0) return false;

    // Validate longitude range (-180 to 180)
    if (longitude < -180.0 || longitude > 180.0) return false;

    return true;
  }
}

class TourItineraryItem {
  final String id;
  final String title;
  final String description;
  final Duration duration;
  final int order;
  final TourLocation? location;
  final List<String> images;
  final Map<String, dynamic>? metadata;

  const TourItineraryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.order,
    this.location,
    this.images = const [],
    this.metadata,
  });

  factory TourItineraryItem.fromJson(Map<String, dynamic> json) {
    return TourItineraryItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      duration: Duration(minutes: json['duration_minutes'] as int),
      order: json['order'] as int,
      location: json['location'] != null
          ? TourLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration_minutes': duration.inMinutes,
      'order': order,
      'location': location?.toJson(),
      'images': images,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TourItineraryItem &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.duration == duration &&
        other.order == order &&
        other.location == location;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, description, duration, order, location);
  }

  @override
  String toString() {
    return 'TourItineraryItem(id: $id, title: $title, order: $order, duration: ${duration.inMinutes}min)';
  }
}

class Tour {
  final String id;
  final String title;
  final String description;
  final String summary;
  final TourCategory category;
  final TourDifficulty difficulty;
  final Duration duration;
  final double price;
  final TourLocation startLocation;
  final TourLocation? endLocation;
  final List<String> highlights;
  final List<String> includes;
  final List<String> excludes;
  final List<String> requirements;
  final List<TourItineraryItem> itinerary;
  final List<String> images;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String guideId;
  final bool isActive;
  final int maxParticipants;
  final List<String> equipment;
  final String? safetyNotes;
  final double? rating;
  final int? reviewCount;
  final int? bookingCount;

  const Tour({
    required this.id,
    required this.title,
    required this.description,
    required this.summary,
    required this.category,
    required this.difficulty,
    required this.duration,
    required this.price,
    required this.startLocation,
    this.endLocation,
    required this.highlights,
    required this.includes,
    required this.excludes,
    required this.requirements,
    required this.itinerary,
    required this.images,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.guideId,
    this.isActive = true,
    this.maxParticipants = 10,
    this.equipment = const [],
    this.safetyNotes,
    this.rating,
    this.reviewCount,
    this.bookingCount,
  });

  factory Tour.fromJson(Map<String, dynamic> json) {
    return Tour(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      summary: json['summary'] as String,
      // ✅ FIXED: Parse category and difficulty from strings
      category: TourCategory.fromString(json['category'] as String),
      difficulty: TourDifficulty.fromString(json['difficulty'] as String),
      duration: Duration(minutes: json['duration_minutes'] as int),
      price: (json['price'] as num).toDouble(),
      startLocation: TourLocation.fromJson(json['start_location'] as Map<String, dynamic>),
      endLocation: json['end_location'] != null
          ? TourLocation.fromJson(json['end_location'] as Map<String, dynamic>)
          : null,
      highlights: (json['highlights'] as List<dynamic>).cast<String>(),
      includes: (json['includes'] as List<dynamic>).cast<String>(),
      excludes: (json['excludes'] as List<dynamic>).cast<String>(),
      requirements: (json['requirements'] as List<dynamic>).cast<String>(),
      itinerary: (json['itinerary'] as List<dynamic>)
          .map((item) => TourItineraryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List<dynamic>).cast<String>(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      guideId: json['guide_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
      maxParticipants: json['max_participants'] as int? ?? 10,
      equipment: (json['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
      safetyNotes: json['safety_notes'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      bookingCount: json['booking_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'summary': summary,
      'category': category.toJson(),
      'difficulty': difficulty.toJson(),
      'duration_minutes': duration.inMinutes,
      'price': price,
      'start_location': startLocation.toJson(),
      'end_location': endLocation?.toJson(),
      'highlights': highlights,
      'includes': includes,
      'excludes': excludes,
      'requirements': requirements,
      'itinerary': itinerary.map((item) => item.toJson()).toList(),
      'images': images,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'guide_id': guideId,
      'is_active': isActive,
      'max_participants': maxParticipants,
      'equipment': equipment,
      'safety_notes': safetyNotes,
      'rating': rating,
      'review_count': reviewCount,
      'booking_count': bookingCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tour && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Tour(id: $id, title: $title, category: $category, difficulty: $difficulty)';
  }
}