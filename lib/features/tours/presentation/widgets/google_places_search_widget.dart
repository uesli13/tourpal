import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../../../../core/constants/app_colors.dart';

class GooglePlacesSearchWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onPlaceSelected;
  final LatLng? initialLocation;

  const GooglePlacesSearchWidget({
    super.key,
    required this.onPlaceSelected,
    this.initialLocation,
  });

  @override
  State<GooglePlacesSearchWidget> createState() => _GooglePlacesSearchWidgetState();
}

class _GooglePlacesSearchWidgetState extends State<GooglePlacesSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<PlaceSearchResult> _searchResults = [];
  bool _isLoading = false;
  bool _showResults = false;

  // Load API key from environment variables
  String get _apiKey {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Google Maps API key not found in environment variables');
    }
    return apiKey;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchField(),
            if (_isLoading) _buildLoadingIndicator(),
            if (_showResults && !_isLoading) _buildSearchResults(),
            if (!_showResults && !_isLoading) _buildInitialState(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Search Places',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for restaurants, attractions, landmarks...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _showResults = false;
                      _searchResults = [];
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: _onSearchChanged,
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Searching places...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.place,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Find amazing places',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for restaurants, attractions, or landmarks\nto add to your tour',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No places found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final place = _searchResults[index];
          return _buildPlaceItem(place);
        },
      ),
    );
  }

  Widget _buildPlaceItem(PlaceSearchResult place) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _selectPlace(place),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPlaceIcon(place.types),
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (place.address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            place.address,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
              if (place.rating > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      place.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (place.priceLevel > 0) ...[
                      const SizedBox(width: 16),
                      Text(
                        '\$' * place.priceLevel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPlaceIcon(List<String> types) {
    if (types.contains('restaurant') || types.contains('food')) {
      return Icons.restaurant;
    } else if (types.contains('tourist_attraction') || types.contains('museum')) {
      return Icons.museum;
    } else if (types.contains('park')) {
      return Icons.park;
    } else if (types.contains('shopping_mall') || types.contains('store')) {
      return Icons.shopping_bag;
    } else if (types.contains('church') || types.contains('place_of_worship')) {
      return Icons.church;
    } else {
      return Icons.place;
    }
  }

  void _onSearchChanged(String value) {
    // Debounce search to avoid too many API calls
    if (value.length >= 3) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_searchController.text == value) {
          _performSearch(value);
        }
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _showResults = true;
    });

    try {
      final results = await _searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching places: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<PlaceSearchResult>> _searchPlaces(String query) async {
    // Use the real Google Places API
    final String baseUrl = 'https://maps.googleapis.com/maps/api/place/textsearch/json';
    
    // Build location bias if initial location is provided
    String locationBias = '';
    if (widget.initialLocation != null) {
      locationBias = '&location=${widget.initialLocation!.latitude},${widget.initialLocation!.longitude}&radius=10000';
    }
    
    final String url = '$baseUrl?query=${Uri.encodeComponent(query)}&key=$_apiKey$locationBias';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];
          
          return results.map<PlaceSearchResult>((place) {
            return PlaceSearchResult(
              placeId: place['place_id'] ?? '',
              name: place['name'] ?? 'Unknown Place',
              address: place['formatted_address'] ?? '',
              location: LatLng(
                place['geometry']['location']['lat']?.toDouble() ?? 0.0,
                place['geometry']['location']['lng']?.toDouble() ?? 0.0,
              ),
              types: List<String>.from(place['types'] ?? []),
              rating: place['rating']?.toDouble() ?? 0.0,
              priceLevel: place['price_level'] ?? 0,
            );
          }).toList();
        } else {
          throw Exception('Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search places: $e');
    }
  }

  Future<void> _selectPlace(PlaceSearchResult place) async {
    // Convert PlaceSearchResult to the format expected by the tour creation flow
    final placeMap = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': place.name,
      'location': GeoPoint(place.location.latitude, place.location.longitude),
      'address': place.address,
      'description': null,
      'stayingDuration': 30, // Default 30 minutes
      'photoUrl': null,
      'placeId': place.placeId,
      'rating': place.rating,
      'types': place.types,
    };

    widget.onPlaceSelected(placeMap);
    Navigator.pop(context);
  }
}

class PlaceSearchResult {
  final String placeId;
  final String name;
  final String address;
  final LatLng location;
  final List<String> types;
  final double rating;
  final int priceLevel;

  PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.address,
    required this.location,
    required this.types,
    this.rating = 0.0,
    this.priceLevel = 0,
  });
}