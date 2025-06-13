import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/place_suggestion.dart';
import '../../../../core/utils/logger.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen>
    with TickerProviderStateMixin {
  late GoogleMapController _mapController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '30');

  // Services
  final GooglePlacesService _placesService = GooglePlacesService();

  // State variables
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isSearching = false;
  List<PlaceSuggestion> _searchResults = []; // Enhanced to include photos
  PlaceDetails? _selectedPlaceDetails;
  String? _selectedPhotoUrl;
  Timer? _searchTimer;
  bool _showSearchOverlay = false;

  // Focus nodes
  final FocusNode _searchFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _searchFocusNode.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permissionStatus = await Permission.location.request();
      if (!permissionStatus.isGranted) return;

      Position position = await Geolocator.getCurrentPosition(
        // DEPRECATED: desiredAccuracy: LocationAccuracy.high,
        // DEPRECATED: timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController.animateCamera(
        CameraUpdate.newLatLng(_selectedLocation!),
      );
    } catch (e) {
      // Use default location (Coimbra, Portugal) if location access fails
      setState(() {
        _selectedLocation = const LatLng(40.63331744571426, -8.659457453141433);
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    AppLogger.logInfo('🔍 Search called with query: "$query"');
    
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _showSearchOverlay = false;
      });
      return;
    }

    if (query.length < 2) {
      setState(() {
        _showSearchOverlay = false;
      });
      return; // Wait for at least 2 characters
    }

    setState(() {
      _isSearching = true;
      _showSearchOverlay = true;
    });

    try {
      final service = GooglePlacesService();
      AppLogger.logInfo('🌐 Making API call...');
      final results = await service.fetchPlacePredictions(query);
      AppLogger.logInfo('📍 Got ${results.length} results');
      
      // Enhance results with photos
      final enhancedResults = <PlaceSuggestion>[];
      
      for (final result in results) {
        try {
          // Fetch place details to get photos for each suggestion
          final placeDetails = await service.fetchPlaceDetails(result.placeId);
          String? thumbnailUrl;
          
          if (placeDetails.photos != null && placeDetails.photos!.isNotEmpty) {
            thumbnailUrl = service.getPhotoUrl(
              placeDetails.photos!.first.photoReference,
              maxWidth: 100, // Small thumbnail for list
            );
          }
          
          enhancedResults.add(PlaceSuggestion(
            suggestion: result,
            thumbnailUrl: thumbnailUrl,
            placeDetails: placeDetails,
          ));
        } catch (e) {
          // If photo fetch fails, add without photo
          enhancedResults.add(PlaceSuggestion(
            suggestion: result,
            thumbnailUrl: null,
            placeDetails: null,
          ));
        }
      }
      
      if (mounted) {
        setState(() {
          _searchResults = enhancedResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      AppLogger.logInfo('❌ Error searching places: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults.clear();
        });
        
        // Show error message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _selectPlace(PlaceSuggestion enhancedPrediction) async {
    final prediction = enhancedPrediction.suggestion;
    setState(() {
      _isSearching = true;
      _searchController.text = prediction.structuredFormatting?.mainText ?? prediction.description;
      _searchResults = [];
    });

    try {
      // Use cached place details if available
      PlaceDetails placeDetails;
      if (enhancedPrediction.placeDetails != null) {
        placeDetails = enhancedPrediction.placeDetails!;
      } else {
        placeDetails = await _placesService.fetchPlaceDetails(prediction.placeId);
      }

      setState(() {
        _selectedLocation = LatLng(
          placeDetails.geometry.location.lat,
          placeDetails.geometry.location.lng,
        );
        _selectedPlaceDetails = placeDetails;
        _nameController.text = placeDetails.name;
        _selectedAddress = placeDetails.formattedAddress ?? '';
        
        // Auto-select first photo if available
        if (placeDetails.photos != null && placeDetails.photos!.isNotEmpty) {
          _selectedPhotoUrl = _placesService.getPhotoUrl(
            placeDetails.photos!.first.photoReference,
            maxWidth: 400,
          );
        }
        
        _isSearching = false;
      });

      // Update map camera
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_selectedLocation!),
      );

      // Clear search focus
      _searchFocusNode.unfocus();
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading place details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _centerOnUserLocation() async {
    if (_selectedLocation != null) {
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _selectedLocation!,
            zoom: 16.0,
          ),
        ),
      );
    } else {
      // Try to get current location again
      await _getCurrentLocation();
    }
  }

  Future<void> _savePlace() async {
    if (_nameController.text.trim().isEmpty || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a place name and location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final place = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'address': _selectedAddress,
      'location': GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
      'stayingDuration': int.tryParse(_durationController.text.trim()) ?? 30,
      'photoUrl': _selectedPhotoUrl,
      'placeDetails': _selectedPlaceDetails,
      'rating': _selectedPlaceDetails?.rating,
      'types': _selectedPlaceDetails?.types,
    };

    Navigator.pop(context, place);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // FULL SCREEN MAP
            _buildFullScreenMap(),
            
            // TOP BAR
            _buildTopBar(),
            
            // SEARCH OVERLAY
            if (_showSearchOverlay)
              Positioned(
                top: 100, // Position right after the search bar with more space
                left: 16,
                right: 16,
                bottom: 20, // Give more space by extending to near bottom
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            height: 150,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Searching for places...',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _searchResults.isEmpty
                            ? const SizedBox(
                                height: 150,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No places found',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Try a different search term',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(8),
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final enhancedPlace = _searchResults[index];
                                  final place = enhancedPlace.suggestion;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: .05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      leading: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: AppColors.primary.withValues(alpha: .1),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(alpha: .2),
                                          ),
                                        ),
                                        child: enhancedPlace.thumbnailUrl != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  enhancedPlace.thumbnailUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(
                                                        Icons.location_on,
                                                        color: AppColors.primary,
                                                        size: 24,
                                                      ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.location_on,
                                                color: AppColors.primary,
                                                size: 24,
                                              ),
                                      ),
                                      title: Text(
                                        place.structuredFormatting?.mainText ?? place.description,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (place.structuredFormatting?.secondaryText != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              place.structuredFormatting!.secondaryText!,
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          if (enhancedPlace.placeDetails?.rating != null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.star,
                                                  size: 14,
                                                  color: Colors.amber[700],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  enhancedPlace.placeDetails!.rating!.toStringAsFixed(1),
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: .1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.add_circle_outline,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      onTap: () {
                                        AppLogger.logInfo('🏛️ Selected place: ${place.description}');
                                        _selectPlace(enhancedPlace);
                                        setState(() {
                                          _showSearchOverlay = false;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ),
            
            // BOTTOM DETAILS CARD - Hide when searching
            if (_selectedLocation != null && !_showSearchOverlay) 
              _buildBottomDetailsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFullScreenMap() {
    return _selectedLocation != null
        ? GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _selectedLocation!,
              zoom: 15.0,
            ),
            onTap: (LatLng position) {
              setState(() {
                _selectedLocation = position;
                _selectedPlaceDetails = null;
                _selectedPhotoUrl = null;
                _showSearchOverlay = false;
              });
              _getAddressFromCoordinates(position);
            },
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                      infoWindow: InfoWindow(
                        title: _nameController.text.isNotEmpty
                            ? _nameController.text
                            : 'Selected Location',
                      ),
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // We'll use our custom button
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
          )
        : const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: .7),
              Colors.black.withValues(alpha: .3),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            // Back Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                iconSize: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Search Bar
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search places...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          )
                        : const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                            icon: const Icon(Icons.clear, color: Colors.grey),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Center Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _centerOnUserLocation,
                icon: const Icon(Icons.my_location, color: AppColors.primary),
                iconSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomDetailsCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Photo and Address Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Small Photo
                GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      color: Colors.grey[50],
                    ),
                    child: _selectedPhotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _selectedPhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          )
                        : const Icon(
                            Icons.add_photo_alternate,
                            color: AppColors.primary,
                            size: 24,
                          ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Picked Address',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedAddress.isNotEmpty ? _selectedAddress : 'Loading address...',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Place Name and Time Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Place Name',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter place name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time to Spend',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _durationController,
                        decoration: InputDecoration(
                          hintText: '30',
                          suffixText: 'min',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Describe this place...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _savePlace,
                icon: const Icon(Icons.add_location, size: 20),
                label: const Text(
                  'Add Place to Tour',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoOptions() {
    if (_selectedPlaceDetails?.photos != null && _selectedPlaceDetails!.photos!.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose Place Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedPlaceDetails!.photos!.length,
                  itemBuilder: (context, index) {
                    final photo = _selectedPlaceDetails!.photos![index];
                    final photoUrl = _placesService.getPhotoUrl(photo.photoReference, maxWidth: 400);
                    
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedPhotoUrl = photoUrl;
                        });
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedPhotoUrl == photoUrl 
                                ? AppColors.primary 
                                : Colors.grey[300]!,
                            width: _selectedPhotoUrl == photoUrl ? 3 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        setState(() {
          _selectedAddress = [
            placemark.name,
            placemark.street,
            placemark.locality,
            placemark.country,
          ].where((element) => element != null && element.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Address not found';
      });
    }
  }

  Timer? _debounceTimer;
  void _onSearchChanged(String query) {
    AppLogger.logInfo('⌨️ Search text changed: "$query"');
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _showSearchOverlay = false;
      });
      return;
    }

    // Don't show overlay until user has typed at least 2 characters
    if (query.trim().length < 2) {
      setState(() {
        _showSearchOverlay = false;
        _isSearching = false;
      });
      return;
    }

    // Show overlay immediately when starting to type (with loading state)
    setState(() {
      _showSearchOverlay = true;
      _isSearching = true;
    });

    // Debounce the search to avoid too many API calls - increased to 1.2 seconds
    _debounceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && query.trim().length >= 2) {
        _searchPlaces(query.trim());
      }
    });
  }
}