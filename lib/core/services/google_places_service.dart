import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import '../config/app_config.dart';

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Fetch place predictions with optional location bias
  /// [location] - Optional location to bias results (lat, lng)
  /// [radius] - Search radius in meters (default: 10000 = 10km)
  /// [types] - Optional place types to filter results
  /// [strictBounds] - If true, only return results within the radius
  Future<List<PlaceAutocomplete>> fetchPlacePredictions(
    String input, {
    LocationBias? location,
    int radius = 10000,
    List<String>? types,
    bool strictBounds = false,
  }) async {
    AppLogger.info('🔍 GooglePlacesService: Fetching predictions for "$input"${location != null ? ' near ${location.lat},${location.lng}' : ''}');
    
    // Add input validation
    if (input.trim().isEmpty || input.length < 2) {
      AppLogger.info('📍 GooglePlacesService: Input too short, returning empty results');
      return [];
    }
    
    final apiKey = AppConfig.googlePlacesApiKey;
    if (apiKey.isEmpty || apiKey == 'GOOGLE_PLACES_API_KEY_NOT_SET') {
      AppLogger.error('❌ GooglePlacesService: API key not configured');
      throw Exception('Google Places API key is not configured. Please check your environment variables.');
    }
    
    // Build URL with location bias parameters
    final encodedInput = Uri.encodeComponent(input.trim());
    var url = '$_baseUrl/autocomplete/json?input=$encodedInput&key=$apiKey';
    
    // Add location bias if provided
    if (location != null) {
      if (strictBounds) {
        // Use strict bounds - only return results within the radius
        url += '&location=${location.lat},${location.lng}&radius=$radius&strictbounds';
      } else {
        // Use location bias - prefer results near the location but don't restrict
        url += '&location=${location.lat},${location.lng}&radius=$radius';
      }
      AppLogger.info('📍 GooglePlacesService: Using location bias: ${location.lat},${location.lng} (radius: ${radius}m, strict: $strictBounds)');
    }
    
    // Add place types filter if provided
    if (types != null && types.isNotEmpty) {
      final typesParam = types.join('|');
      url += '&types=$typesParam';
      AppLogger.info('🏷️ GooglePlacesService: Filtering by types: $typesParam');
    }
    
    // Add language and region preferences
    url += '&language=en&components=country:pt'; // Prefer Portuguese results
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10)); // Add timeout
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        // Check API response status
        if (json['status'] != 'OK' && json['status'] != 'ZERO_RESULTS') {
          final status = json['status'];
          final errorMessage = json['error_message'] ?? 'Unknown error';
          AppLogger.error('❌ GooglePlacesService: API Error - $status: $errorMessage');
          
          // Provide specific error messages for common issues
          switch (status) {
            case 'REQUEST_DENIED':
              throw Exception('Google Places API access denied. Please check:\n1. API key is valid\n2. Places API is enabled\n3. Billing is set up\n4. API key restrictions allow this app');
            case 'OVER_QUERY_LIMIT':
              throw Exception('Google Places API quota exceeded. Please try again later.');
            case 'INVALID_REQUEST':
              throw Exception('Invalid search request. Please try a different search term.');
            default:
              throw Exception('Google Places API Error: $status - $errorMessage');
          }
        }
        
        if (json['status'] == 'ZERO_RESULTS') {
          AppLogger.info('📍 GooglePlacesService: No results found for query');
          return [];
        }
        
        final predictions = json['predictions'] as List? ?? [];
        AppLogger.info('📍 GooglePlacesService: Got ${predictions.length} results');
        
        return predictions
            .map((prediction) => PlaceAutocomplete.fromJson(prediction))
            .toList();
            
      } else {
        AppLogger.error('❌ GooglePlacesService: HTTP ${response.statusCode} - ${response.body}');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } on TimeoutException {
      AppLogger.error('⏰ GooglePlacesService: Request timeout');
      throw Exception('Request timeout - please check your internet connection');
    } catch (e) {
      AppLogger.error('💥 GooglePlacesService: Exception during prediction fetch', e);
      if (e.toString().contains('Google Places API')) {
        rethrow; // Preserve API-specific errors
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  /// Search for nearby places using the Nearby Search API
  /// This is better for finding specific types of places in an area
  Future<List<PlaceNearby>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 10000,
    String? type,
    String? keyword,
    int? minPrice,
    int? maxPrice,
    bool openNow = false,
  }) async {
    AppLogger.info('🔍 GooglePlacesService: Searching nearby places at $latitude,$longitude');
    
    final apiKey = AppConfig.googlePlacesApiKey;
    if (apiKey.isEmpty || apiKey == 'GOOGLE_PLACES_API_KEY_NOT_SET') {
      AppLogger.error('❌ GooglePlacesService: API key not configured');
      throw Exception('Google Places API key is not configured. Please check your environment variables.');
    }
    
    var url = '$_baseUrl/nearbysearch/json?location=$latitude,$longitude&radius=$radius&key=$apiKey';
    
    // Add optional parameters
    if (type != null) url += '&type=$type';
    if (keyword != null) url += '&keyword=${Uri.encodeComponent(keyword)}';
    if (minPrice != null) url += '&minprice=$minPrice';
    if (maxPrice != null) url += '&maxprice=$maxPrice';
    if (openNow) url += '&opennow';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['status'] != 'OK' && json['status'] != 'ZERO_RESULTS') {
          AppLogger.error('❌ GooglePlacesService: Nearby Search API Error - ${json['status']}');
          throw Exception('Google Places API Error: ${json['status']}');
        }
        
        if (json['status'] == 'ZERO_RESULTS') {
          AppLogger.info('📍 GooglePlacesService: No nearby places found');
          return [];
        }
        
        final results = json['results'] as List? ?? [];
        AppLogger.info('📍 GooglePlacesService: Found ${results.length} nearby places');
        
        return results
            .map((result) => PlaceNearby.fromJson(result))
            .toList();
      } else {
        AppLogger.error('❌ GooglePlacesService: HTTP ${response.statusCode} - ${response.body}');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('💥 GooglePlacesService: Exception during nearby search', e);
      throw Exception('Error searching nearby places: ${e.toString()}');
    }
  }

  /// Text search for places with location bias
  /// Good for searching "restaurants in Coimbra" or "hotels near downtown"
  Future<List<PlaceNearby>> textSearch(
    String query, {
    LocationBias? location,
    int radius = 10000,
    String? type,
    int? minPrice,
    int? maxPrice,
    bool openNow = false,
  }) async {
    AppLogger.info('🔍 GooglePlacesService: Text search for "$query"');
    
    final apiKey = AppConfig.googlePlacesApiKey;
    if (apiKey.isEmpty || apiKey == 'GOOGLE_PLACES_API_KEY_NOT_SET') {
      AppLogger.error('❌ GooglePlacesService: API key not configured');
      throw Exception('Google Places API key is not configured.');
    }
    
    final encodedQuery = Uri.encodeComponent(query);
    var url = '$_baseUrl/textsearch/json?query=$encodedQuery&key=$apiKey';
    
    // Add location bias if provided
    if (location != null) {
      url += '&location=${location.lat},${location.lng}&radius=$radius';
    }
    
    // Add optional parameters
    if (type != null) url += '&type=$type';
    if (minPrice != null) url += '&minprice=$minPrice';
    if (maxPrice != null) url += '&maxprice=$maxPrice';
    if (openNow) url += '&opennow';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        if (json['status'] != 'OK' && json['status'] != 'ZERO_RESULTS') {
          AppLogger.error('❌ GooglePlacesService: Text Search API Error - ${json['status']}');
          throw Exception('Google Places API Error: ${json['status']}');
        }
        
        if (json['status'] == 'ZERO_RESULTS') {
          AppLogger.info('📍 GooglePlacesService: No results found for text search');
          return [];
        }
        
        final results = json['results'] as List? ?? [];
        AppLogger.info('📍 GooglePlacesService: Text search found ${results.length} places');
        
        return results
            .map((result) => PlaceNearby.fromJson(result))
            .toList();
      } else {
        AppLogger.error('❌ GooglePlacesService: HTTP ${response.statusCode} - ${response.body}');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('💥 GooglePlacesService: Exception during text search', e);
      throw Exception('Error in text search: ${e.toString()}');
    }
  }

  Future<PlaceDetails> fetchPlaceDetails(String placeId) async {
    AppLogger.info('🏛️ GooglePlacesService: Fetching details for place $placeId');
    
    final apiKey = AppConfig.googlePlacesApiKey;
    if (apiKey.isEmpty || apiKey == 'GOOGLE_PLACES_API_KEY_NOT_SET') {
      AppLogger.error('❌ GooglePlacesService: API key not configured');
      throw Exception('Google Places API key is not configured. Please check your environment variables.');
    }
    
    final url = '$_baseUrl/details/json?place_id=$placeId&key=$apiKey';
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10)); // Add timeout
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        
        // Check API response status
        if (json['status'] != 'OK') {
          AppLogger.error('❌ GooglePlacesService: Details API Error - ${json['status']}: ${json['error_message'] ?? 'Unknown error'}');
          throw Exception('Google Places API Error: ${json['status']}');
        }
        
        AppLogger.info('✅ GooglePlacesService: Successfully fetched place details');
        return PlaceDetails.fromJson(json['result']);
      } else {
        AppLogger.error('❌ GooglePlacesService: Details HTTP ${response.statusCode} - ${response.body}');
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } on TimeoutException {
      AppLogger.error('⏰ GooglePlacesService: Details request timeout');
      throw Exception('Request timeout - please check your internet connection');
    } catch (e) {
      AppLogger.error('💥 GooglePlacesService: Exception during details fetch', e);
      if (e.toString().contains('Google Places API Error')) {
        rethrow; // Preserve API-specific errors
      }
      throw Exception('Error fetching place details: ${e.toString()}');
    }
  }

  String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    AppLogger.debug('📸 GooglePlacesService: Generating photo URL');
    final apiKey = AppConfig.googlePlacesApiKey;
    return '$_baseUrl/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=$apiKey';
  }
}

/// Location bias helper class
class LocationBias {
  final double lat;
  final double lng;
  
  LocationBias({required this.lat, required this.lng});
  
  /// Create location bias for Coimbra, Portugal
  static LocationBias coimbra() => LocationBias(lat: 40.2033, lng: -8.4103);
  
  /// Create location bias for Lisbon, Portugal
  static LocationBias lisbon() => LocationBias(lat: 38.7223, lng: -9.1393);
  
  /// Create location bias for Porto, Portugal
  static LocationBias porto() => LocationBias(lat: 41.1579, lng: -8.6291);
}

// Common place types for tourism
class PlaceTypes {
  static const String restaurant = 'restaurant';
  static const String lodging = 'lodging';
  static const String touristAttraction = 'tourist_attraction';
  static const String museum = 'museum';
  static const String park = 'park';
  static const String shopping = 'shopping_mall';
  static const String store = 'store';
  static const String cafe = 'cafe';
  static const String bar = 'bar';
  static const String nightClub = 'night_club';
  static const String church = 'church';
  static const String library = 'library';
  static const String university = 'university';
  static const String hospital = 'hospital';
  static const String pharmacy = 'pharmacy';
  static const String gasStation = 'gas_station';
  static const String bank = 'bank';
  static const String atm = 'atm';
}

// Place autocomplete model
class PlaceAutocomplete {
  final String placeId;
  final String description;
  final StructuredFormatting? structuredFormatting;
  final List<String> types;
  
  PlaceAutocomplete({
    required this.placeId,
    required this.description,
    this.structuredFormatting,
    required this.types,
  });
  
  factory PlaceAutocomplete.fromJson(Map<String, dynamic> json) {
    return PlaceAutocomplete(
      placeId: json['place_id'],
      description: json['description'],
      structuredFormatting: json['structured_formatting'] != null
          ? StructuredFormatting.fromJson(json['structured_formatting'])
          : null,
      types: List<String>.from(json['types'] ?? []),
    );
  }
}

// Structured formatting for autocomplete
class StructuredFormatting {
  final String? mainText;
  final String? secondaryText;
  
  StructuredFormatting({
    this.mainText,
    this.secondaryText,
  });
  
  factory StructuredFormatting.fromJson(Map<String, dynamic> json) {
    return StructuredFormatting(
      mainText: json['main_text'],
      secondaryText: json['secondary_text'],
    );
  }
}

// Place details model
class PlaceDetails {
  final String placeId;
  final String name;
  final String? formattedAddress;
  final PlaceGeometry geometry;
  final double? rating;
  final int? userRatingsTotal;
  final List<PlacePhoto>? photos;
  final List<String> types;
  final PlaceOpeningHours? openingHours;
  final String? phoneNumber;
  final String? website;
  final int? priceLevel;
  
  PlaceDetails({
    required this.placeId,
    required this.name,
    this.formattedAddress,
    required this.geometry,
    this.rating,
    this.userRatingsTotal,
    this.photos,
    required this.types,
    this.openingHours,
    this.phoneNumber,
    this.website,
    this.priceLevel,
  });
  
  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      placeId: json['place_id'],
      name: json['name'],
      formattedAddress: json['formatted_address'],
      geometry: PlaceGeometry.fromJson(json['geometry']),
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      photos: (json['photos'] as List<dynamic>?)
          ?.map((photo) => PlacePhoto.fromJson(photo))
          .toList(),
      types: List<String>.from(json['types'] ?? []),
      openingHours: json['opening_hours'] != null 
          ? PlaceOpeningHours.fromJson(json['opening_hours'])
          : null,
      phoneNumber: json['international_phone_number'],
      website: json['website'],
      priceLevel: json['price_level'],
    );
  }
}

// Place geometry model
class PlaceGeometry {
  final PlaceLocation location;
  
  PlaceGeometry({
    required this.location,
  });
  
  factory PlaceGeometry.fromJson(Map<String, dynamic> json) {
    return PlaceGeometry(
      location: PlaceLocation.fromJson(json['location']),
    );
  }
}

// Place location model
class PlaceLocation {
  final double lat;
  final double lng;
  
  PlaceLocation({
    required this.lat,
    required this.lng,
  });
  
  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      lat: json['lat'].toDouble(),
      lng: json['lng'].toDouble(),
    );
  }
}

// Place photo model
class PlacePhoto {
  final String photoReference;
  final int width;
  final int height;
  final List<String> htmlAttributions;
  
  PlacePhoto({
    required this.photoReference,
    required this.width,
    required this.height,
    required this.htmlAttributions,
  });
  
  factory PlacePhoto.fromJson(Map<String, dynamic> json) {
    return PlacePhoto(
      photoReference: json['photo_reference'],
      width: json['width'],
      height: json['height'],
      htmlAttributions: List<String>.from(json['html_attributions'] ?? []),
    );
  }
}

// Opening hours model
class PlaceOpeningHours {
  final bool openNow;
  final List<String> weekdayText;
  
  PlaceOpeningHours({
    required this.openNow,
    required this.weekdayText,
  });
  
  factory PlaceOpeningHours.fromJson(Map<String, dynamic> json) {
    return PlaceOpeningHours(
      openNow: json['open_now'] ?? false,
      weekdayText: List<String>.from(json['weekday_text'] ?? []),
    );
  }
}

// Nearby place model
class PlaceNearby {
  final String placeId;
  final String name;
  final String? vicinity;
  final double latitude;
  final double longitude;
  final double? rating;
  final int? userRatingsTotal;
  final List<String> types;
  final int? priceLevel;
  final String? icon;
  final bool? openNow;
  
  PlaceNearby({
    required this.placeId,
    required this.name,
    this.vicinity,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.userRatingsTotal,
    required this.types,
    this.priceLevel,
    this.icon,
    this.openNow,
  });
  
  factory PlaceNearby.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final location = geometry['location'];
    
    return PlaceNearby(
      placeId: json['place_id'],
      name: json['name'],
      vicinity: json['vicinity'],
      latitude: location['lat'].toDouble(),
      longitude: location['lng'].toDouble(),
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      types: List<String>.from(json['types'] ?? []),
      priceLevel: json['price_level'],
      icon: json['icon'],
      openNow: json['opening_hours']?['open_now'],
    );
  }
}