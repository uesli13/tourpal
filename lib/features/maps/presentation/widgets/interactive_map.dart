import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/constants/app_colors.dart';

class InteractiveMap extends StatefulWidget {
  final Function(double lat, double lng, String name) onLocationSelected;
  final double? initialLat;
  final double? initialLng;
  final List<MapMarker>? markers;
  final bool showUserLocation;
  final bool allowMultipleSelection;

  const InteractiveMap({
    super.key,
    required this.onLocationSelected,
    this.initialLat,
    this.initialLng,
    this.markers,
    this.showUserLocation = true,
    this.allowMultipleSelection = true,
  });

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng _initialPosition = const LatLng(40.6306, -8.6588); // Aveiro University, Portugal
  bool _isLocationPermissionGranted = false;
  String? _selectedLocationName;
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() async {
    // Set initial position if provided
    if (widget.initialLat != null && widget.initialLng != null) {
      _initialPosition = LatLng(widget.initialLat!, widget.initialLng!);
    }

    // Request location permission
    _requestLocationPermission();
  }

  void _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        setState(() {
          _isLocationPermissionGranted = true;
        });

        // Get current location if permission granted
        if (widget.showUserLocation) {
          _getCurrentLocation();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting location permission: $e');
      }
    }
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
      });

      // Move camera to current location
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 12.0,
              ),
              markers: _markers,
              onTap: _onMapTapped,
              myLocationEnabled: _isLocationPermissionGranted && widget.showUserLocation,
              myLocationButtonEnabled: false, // We'll add our own button
              mapType: MapType.normal,
              zoomControlsEnabled: false, // We'll add our own controls
              compassEnabled: true,
              trafficEnabled: false,
              buildingsEnabled: true,
              // Enable all gestures for smooth interaction
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              rotateGesturesEnabled: true,
              mapToolbarEnabled: true,
            ),
            
            // Custom controls
            _buildMapControls(),
            
            // Location info panel
            if (_selectedPosition != null && _selectedLocationName != null)
              _buildLocationInfo(),
              
            // Map header
            _buildMapHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Column(
        children: [
          _buildControlButton(
            icon: Icons.add,
            onPressed: _zoomIn,
            tooltip: 'Zoom In',
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.remove,
            onPressed: _zoomOut,
            tooltip: 'Zoom Out',
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: Icons.my_location,
            onPressed: _getCurrentLocation,
            tooltip: 'My Location',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: isActive ? Colors.white : AppColors.textPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Selected Location',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedLocationName ?? 'Unknown Location',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _confirmSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapHeader() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Tap to add locations',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTapped(LatLng position) async {
    // Reverse geocoding to get location name
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String locationName = 'Unknown Location';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        locationName = _formatLocationName(place);
      }

      setState(() {
        _selectedPosition = position;
        _selectedLocationName = locationName;
        
        // Add marker to show selection
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_location'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: 'Selected Location',
              snippet: locationName,
            ),
          ),
        );
      });

      HapticFeedback.mediumImpact();
      
      // Call the callback
      widget.onLocationSelected(
        position.latitude,
        position.longitude,
        locationName,
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location name: $e');
      }
      setState(() {
        _selectedPosition = position;
        _selectedLocationName = 'Selected Location';
      });
      
      widget.onLocationSelected(
        position.latitude,
        position.longitude,
        'Selected Location',
      );
    }
  }

  String _formatLocationName(Placemark place) {
    List<String> parts = [];
    
    // Prioritize meaningful location names
    if (place.name != null && place.name!.isNotEmpty && place.name! != place.street) {
      parts.add(place.name!);
    }
    
    if (place.street != null && place.street!.isNotEmpty) {
      parts.add(place.street!);
    }
    
    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }
    
    if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
      parts.add(place.subAdministrativeArea!);
    }
    
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }
    
    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }
    
    // Filter out numeric-only parts and duplicates
    List<String> filteredParts = [];
    for (String part in parts) {
      // Skip if it's just a number or already exists
      if (!RegExp(r'^\d+$').hasMatch(part) && 
          !filteredParts.contains(part) &&
          part.trim().isNotEmpty) {
        filteredParts.add(part);
      }
    }
    
    // If we have meaningful parts, use them, otherwise use a fallback
    if (filteredParts.isNotEmpty) {
      return filteredParts.take(3).join(', '); // Limit to 3 parts max
    } else {
      return 'Selected Location';
    }
  }

  void _confirmSelection() {
    if (_selectedPosition != null && _selectedLocationName != null) {
      // Remove the temporary marker
      setState(() {
        _markers.removeWhere((marker) => marker.markerId == const MarkerId('selected_location'));
        _selectedPosition = null;
        _selectedLocationName = null;
      });
      
      HapticFeedback.lightImpact();
    }
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
    HapticFeedback.selectionClick();
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
    HapticFeedback.selectionClick();
  }
}

// Keep the MapMarker class for compatibility
class MapMarker {
  final double lat;
  final double lng;
  final String name;
  final IconData icon;
  final Color color;
  final double screenX;
  final double screenY;

  const MapMarker({
    required this.lat,
    required this.lng,
    required this.name,
    required this.icon,
    required this.color,
    required this.screenX,
    required this.screenY,
  });
}