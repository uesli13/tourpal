import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';

class FullScreenTourMap extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final Function(List<Map<String, dynamic>>) onLocationsUpdated;

  const FullScreenTourMap({
    super.key,
    required this.locations,
    required this.onLocationsUpdated,
  });

  @override
  State<FullScreenTourMap> createState() => _FullScreenTourMapState();
}

class _FullScreenTourMapState extends State<FullScreenTourMap> {
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String _totalDistance = '';
  String _totalDuration = '';
  List<Map<String, dynamic>> _nearbyPlaces = [];
  bool _isLoadingPlaces = false;
  bool _showPlacesSearch = false;

  @override
  void initState() {
    super.initState();
    _setupMarkersAndRoute();
  }

  void _setupMarkersAndRoute() {
    _markers.clear();
    _polylines.clear();

    // Create markers for each location
    for (int i = 0; i < widget.locations.length; i++) {
      final location = widget.locations[i];
      _markers.add(
        Marker(
          markerId: MarkerId('location_$i'),
          position: LatLng(location['latitude'], location['longitude']),
          infoWindow: InfoWindow(
            title: location['name'] ?? 'Location ${i + 1}',
            snippet: location['address'] ?? '',
            onTap: () => _showLocationDetails(location),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
          ),
          onTap: () => _showLocationDetails(location),
        ),
      );
    }

    // Create route polyline if more than 1 location
    if (widget.locations.length > 1) {
      _createRoutePolyline();
    }

    setState(() {});
  }

  void _createRoutePolyline() {
    List<LatLng> routePoints = [];
    
    for (final location in widget.locations) {
      routePoints.add(LatLng(location['latitude'], location['longitude']));
    }

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('tour_route'),
        points: routePoints,
        color: AppColors.primary,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );

    // Calculate total distance and duration
    _calculateRouteMetrics();
  }

  void _calculateRouteMetrics() {
    if (widget.locations.length < 2) return;

    double totalDistanceMeters = 0;
    
    for (int i = 0; i < widget.locations.length - 1; i++) {
      final current = widget.locations[i];
      final next = widget.locations[i + 1];
      
      final distance = Geolocator.distanceBetween(
        current['latitude'],
        current['longitude'],
        next['latitude'],
        next['longitude'],
      );
      
      totalDistanceMeters += distance;
    }

    final totalKm = totalDistanceMeters / 1000;
    final walkingMinutes = (totalDistanceMeters / 83.33).round(); // Average walking speed 5 km/h

    setState(() {
      _totalDistance = totalKm >= 1 
          ? '${totalKm.toStringAsFixed(1)} km'
          : '${totalDistanceMeters.round()} m';
      _totalDuration = walkingMinutes >= 60
          ? '${(walkingMinutes / 60).floor()}h ${walkingMinutes % 60}min'
          : '${walkingMinutes}min';
    });
  }

  Future<void> _searchNearbyPlaces(LatLng position) async {
    setState(() {
      _isLoadingPlaces = true;
      _nearbyPlaces.clear();
      _showPlacesSearch = true;
    });

    // Simulate nearby places search (you would integrate with Google Places API)
    await Future.delayed(const Duration(seconds: 1));

    final mockPlaces = [
      {
        'name': 'Café Central',
        'type': 'Café',
        'rating': 4.5,
        'address': 'Main Street 123',
        'latitude': position.latitude + 0.001,
        'longitude': position.longitude + 0.001,
      },
      {
        'name': 'Pizza Palace',
        'type': 'Restaurant',
        'rating': 4.2,
        'address': 'Food Court Avenue',
        'latitude': position.latitude - 0.001,
        'longitude': position.longitude + 0.001,
      },
      {
        'name': 'City Museum',
        'type': 'Museum',
        'rating': 4.8,
        'address': 'Culture Street 45',
        'latitude': position.latitude + 0.002,
        'longitude': position.longitude - 0.001,
      },
      {
        'name': 'Park & Garden',
        'type': 'Park',
        'rating': 4.3,
        'address': 'Green Avenue 89',
        'latitude': position.latitude + 0.0015,
        'longitude': position.longitude - 0.002,
      },
    ];

    setState(() {
      _nearbyPlaces = mockPlaces;
      _isLoadingPlaces = false;
    });
  }

  void _addPlaceToTour(Map<String, dynamic> place) {
    final newLocation = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': place['name'],
      'address': place['address'],
      'latitude': place['latitude'],
      'longitude': place['longitude'],
      'description': '${place['type']} • Rating: ${place['rating']}⭐',
      'photo': null,
    };

    final updatedLocations = List<Map<String, dynamic>>.from(widget.locations);
    updatedLocations.add(newLocation);
    
    widget.onLocationsUpdated(updatedLocations);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Added "${place['name']}" to your tour!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      _showPlacesSearch = false;
    });

    _setupMarkersAndRoute();
  }

  void _showLocationDetails(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // HANDLE
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // HEADER
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        location['name'] ?? 'Unnamed Location',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // CONTENT
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // PHOTO
                      if (location['photo'] != null) ...[
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(location['photo']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // DESCRIPTION
                      if (location['description'] != null && location['description'].isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.description, color: AppColors.primary, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                location['description'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // ADDRESS
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Address',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    location['address'] ?? 'No address available',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // GOOGLE MAP
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              if (widget.locations.isNotEmpty) {
                // Focus on tour locations
                final bounds = _calculateBounds();
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 100),
                );
              }
            },
            initialCameraPosition: widget.locations.isNotEmpty
                ? CameraPosition(
                    target: LatLng(
                      widget.locations.first['latitude'],
                      widget.locations.first['longitude'],
                    ),
                    zoom: 15,
                  )
                : const CameraPosition(target: LatLng(38.7223, -9.1393), zoom: 15),
            markers: _markers,
            polylines: _polylines,
            onTap: _searchNearbyPlaces,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // TOP BAR
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: .1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Interactive Tour Map',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Tap anywhere to find nearby places',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showPlacesSearch = !_showPlacesSearch;
                      });
                    },
                    icon: Icon(
                      _showPlacesSearch ? Icons.close : Icons.search,
                      color: AppColors.primary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: .1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // PLACES SEARCH PANEL
          if (_showPlacesSearch)
            Positioned(
              top: 120,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // HEADER
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.place,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Nearby Places',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // PLACES LIST
                    Expanded(
                      child: _isLoadingPlaces
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _nearbyPlaces.length,
                              itemBuilder: (context, index) {
                                final place = _nearbyPlaces[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: .1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.place,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      place['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place['type'],
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, size: 12, color: Colors.orange),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${place['rating']}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () => _addPlaceToTour(place),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        minimumSize: Size.zero,
                                      ),
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          
          // ROUTE INFO BOTTOM CARD
          if (widget.locations.length > 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .1),
                      blurRadius: 15,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.route,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Walking Route Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.location_on,
                            label: 'Locations',
                            value: '${widget.locations.length}',
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value: _totalDistance,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.access_time,
                            label: 'Walking Time',
                            value: _totalDuration,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  LatLngBounds _calculateBounds() {
    if (widget.locations.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(38.7223, -9.1393),
        northeast: LatLng(38.7223, -9.1393),
      );
    }

    double minLat = widget.locations.first['latitude'];
    double maxLat = widget.locations.first['latitude'];
    double minLng = widget.locations.first['longitude'];
    double maxLng = widget.locations.first['longitude'];

    for (final location in widget.locations) {
      minLat = minLat < location['latitude'] ? minLat : location['latitude'];
      maxLat = maxLat > location['latitude'] ? maxLat : location['latitude'];
      minLng = minLng < location['longitude'] ? minLng : location['longitude'];
      maxLng = maxLng > location['longitude'] ? maxLng : location['longitude'];
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}