class LocationSuggestion {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final String category;
  final double rating;
  final List<String> imageUrls;
  final List<String> tags;
  final double distanceKm;
  final String priceLevel; // '$', '$$', '$$$', '$$$$'
  final String openingHours;
  final bool isPopular;

  const LocationSuggestion({
    required this.id,
    required this.name,
    this.description = '',
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.category = '',
    this.rating = 0.0,
    this.imageUrls = const [],
    this.tags = const [],
    this.distanceKm = 0.0,
    this.priceLevel = '\$',
    this.openingHours = '',
    this.isPopular = false,
  });

  factory LocationSuggestion.fromGooglePlaces(Map<String, dynamic> json, double userLat, double userLng) {
    final location = json['geometry']['location'];
    final lat = location['lat'].toDouble();
    final lng = location['lng'].toDouble();
    
    return LocationSuggestion(
      id: json['place_id'] ?? '',
      name: json['name'] ?? '',
      description: json['editorial_summary']?['overview'] ?? '',
      latitude: lat,
      longitude: lng,
      address: json['vicinity'] ?? json['formatted_address'] ?? '',
      category: (json['types'] as List?)?.first ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      imageUrls: _extractPhotos(json['photos']),
      tags: List<String>.from(json['types'] ?? []),
      distanceKm: _calculateDistance(userLat, userLng, lat, lng),
      priceLevel: _convertPriceLevel(json['price_level']),
      openingHours: _extractOpeningHours(json['opening_hours']),
      isPopular: (json['user_ratings_total'] ?? 0) > 1000,
    );
  }

  static List<String> _extractPhotos(List<dynamic>? photos) {
    if (photos == null || photos.isEmpty) return [];
    
    return photos.take(3).map((photo) {
      final photoReference = photo['photo_reference'];
      return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=YOUR_API_KEY';
    }).toList();
  }

  static String _convertPriceLevel(int? priceLevel) {
    switch (priceLevel) {
      case 1: return '\$';
      case 2: return '\$\$';
      case 3: return '\$\$\$';
      case 4: return '\$\$\$\$';
      default: return '\$';
    }
  }

  static String _extractOpeningHours(Map<String, dynamic>? openingHours) {
    if (openingHours == null) return '';
    if (openingHours['open_now'] == true) return 'Open Now';
    return 'Closed';
  }

  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    // Simple distance calculation (you'd use a proper haversine formula in production)
    const double earthRadius = 6371; // km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = (dLat / 2).abs() + (dLng / 2).abs();
    return earthRadius * 2 * a; // Simplified calculation
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}