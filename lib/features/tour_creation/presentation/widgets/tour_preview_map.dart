import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';

class TourPreviewMap extends StatefulWidget {
  final String tourTitle;
  final List<Map<String, dynamic>> places;
  final Function(List<Map<String, dynamic>>) onPlacesUpdated;

  const TourPreviewMap({
    super.key,
    required this.tourTitle,
    required this.places,
    required this.onPlacesUpdated,
  });

  @override
  State<TourPreviewMap> createState() => _TourPreviewMapState();
}

class _TourPreviewMapState extends State<TourPreviewMap> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _totalDistance = '';
  String _totalDuration = '';
  int _selectedPlaceIndex = -1;

  @override
  void initState() {
    super.initState();
    _setupMarkersAndRoute();
  }

  void _setupMarkersAndRoute() {
    _markers.clear();
    _polylines.clear();

    // Create markers for each place
    for (int i = 0; i < widget.places.length; i++) {
      final place = widget.places[i];
      _markers.add(
        Marker(
          markerId: MarkerId('place_$i'),
          position: LatLng(place['latitude'], place['longitude']),
          infoWindow: InfoWindow(
            title: place['name'] ?? 'Place ${i + 1}',
            snippet: place['address'] ?? '',
            onTap: () => _selectPlace(i),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 ? BitmapDescriptor.hueGreen : 
            i == widget.places.length - 1 ? BitmapDescriptor.hueRed : 
            BitmapDescriptor.hueBlue,
          ),
          onTap: () => _selectPlace(i),
        ),
      );
    }

    // Create route polyline if more than 1 place
    if (widget.places.length > 1) {
      _createRoutePolyline();
    }

    setState(() {});
  }

  void _createRoutePolyline() {
    List<LatLng> routePoints = [];
    
    for (final place in widget.places) {
      routePoints.add(LatLng(place['latitude'], place['longitude']));
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
    if (widget.places.length < 2) return;

    double totalDistanceMeters = 0;
    int totalTimeMinutes = 0;
    
    for (int i = 0; i < widget.places.length - 1; i++) {
      final current = widget.places[i];
      final next = widget.places[i + 1];
      
      final distance = Geolocator.distanceBetween(
        current['latitude'],
        current['longitude'],
        next['latitude'],
        next['longitude'],
      );
      
      totalDistanceMeters += distance;
    }

    // Add time to spend at each place
    for (final place in widget.places) {
      if (place['timeToSpend'] != null) {
        totalTimeMinutes += place['timeToSpend'] as int;
      }
    }

    final totalKm = totalDistanceMeters / 1000;
    final walkingMinutes = (totalDistanceMeters / 83.33).round(); // Average walking speed 5 km/h
    final totalTourMinutes = walkingMinutes + totalTimeMinutes;

    setState(() {
      _totalDistance = totalKm >= 1 
          ? '${totalKm.toStringAsFixed(1)} km'
          : '${totalDistanceMeters.round()} m';
      _totalDuration = totalTourMinutes >= 60
          ? '${(totalTourMinutes / 60).floor()}h ${totalTourMinutes % 60}min'
          : '${totalTourMinutes}min';
    });
  }

  void _selectPlace(int index) {
    setState(() {
      _selectedPlaceIndex = index;
    });
    
    // Animate camera to selected place
    if (_controller != null) {
      final place = widget.places[index];
      _controller!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(place['latitude'], place['longitude']),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // GOOGLE MAP
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
              if (widget.places.isNotEmpty) {
                // Focus on tour places
                final bounds = _calculateBounds();
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 100),
                );
              }
            },
            initialCameraPosition: widget.places.isNotEmpty
                ? CameraPosition(
                    target: LatLng(
                      widget.places.first['latitude'],
                      widget.places.first['longitude'],
                    ),
                    zoom: 15,
                  )
                : const CameraPosition(target: LatLng(38.7223, -9.1393), zoom: 15),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // TOP BAR
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(26),
              height: 45,
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
                        Text(
                          widget.tourTitle.isNotEmpty ? widget.tourTitle : 'Tour Preview',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Tap markers to see place details',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showTourOverview,
                    icon: const Icon(Icons.list, color: AppColors.primary),
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
          
          // SELECTED PLACE DETAILS BOTTOM SHEET
          if (_selectedPlaceIndex >= 0)
            _buildPlaceDetailsSheet(),
          
          // TOUR STATS BOTTOM CARD (when no place selected)
          if (_selectedPlaceIndex < 0 && widget.places.length > 1)
            _buildTourStatsCard(),
        ],
      ),
    );
  }

  Widget _buildPlaceDetailsSheet() {
    final place = widget.places[_selectedPlaceIndex];
    
    return DraggableScrollableSheet(
      initialChildSize: 0.4, // Start smaller
      minChildSize: 0.2, // Allow very small
      maxChildSize: 0.7, // Don't take full screen
      builder: (context, scrollController) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .1),
                blurRadius: 15,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // DRAG HANDLE
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // HEADER WITH PHOTO BACKGROUND OR GRADIENT
              Container(
                height: 120, // Fixed height for header
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  // Use photo as background if available, otherwise gradient
                  image: place['image'] != null 
                      ? DecorationImage(
                          image: FileImage(File(place['image'])),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: place['image'] == null 
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    // Dark overlay for better text visibility when using photo
                    if (place['image'] != null)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: .3),
                              Colors.black.withValues(alpha: .7),
                            ],
                          ),
                        ),
                      ),
                    
                    // Header content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Place number badge
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${_selectedPlaceIndex + 1}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Place info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  place['name'] ?? 'Unnamed Place',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 3,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (place['timeToSpend'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '⏱️ ${place['timeToSpend']} minutes',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                // Address preview
                                Text(
                                  place['address'] ?? 'No address',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Close button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedPlaceIndex = -1;
                                });
                              },
                              icon: const Icon(
                                Icons.close, 
                                color: AppColors.primary,
                                size: 20,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // CONTENT (no photo here anymore since it's in header)
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // DESCRIPTION (no photo section anymore)
                      if (place['description'] != null && place['description'].isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.description, color: AppColors.primary, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                place['description'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // DETAILED ADDRESS INFO
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.place, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Full Address',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    place['address'] ?? 'No address available',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // COMPACT NAVIGATION BUTTONS
                      Row(
                        children: [
                          if (_selectedPlaceIndex > 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _selectPlace(_selectedPlaceIndex - 1),
                                icon: const Icon(Icons.arrow_back, size: 14),
                                label: const Text(
                                  'Previous',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          if (_selectedPlaceIndex > 0 && _selectedPlaceIndex < widget.places.length - 1)
                            const SizedBox(width: 8),
                          if (_selectedPlaceIndex < widget.places.length - 1)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _selectPlace(_selectedPlaceIndex + 1),
                                icon: const Icon(Icons.arrow_forward, size: 14),
                                label: const Text(
                                  'Next',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 20), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTourStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16), // Reduced from 20
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
          // COMPACT HEADER
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Smaller icon container
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.route,
                  color: Colors.white,
                  size: 16, // Smaller icon
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tour Summary',
                style: TextStyle(
                  fontSize: 14, // Smaller font
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Add a minimize button
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedPlaceIndex = 0; // Show first place details instead
                  });
                },
                icon: const Icon(Icons.expand_less, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced spacing
          // COMPACT STATS ROW
          Row(
            children: [
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.location_on,
                  label: 'Places',
                  value: '${widget.places.length}',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: _totalDistance,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactStatCard(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: _totalDuration,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6), // Much smaller padding
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16), // Smaller icon
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12, // Smaller font
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9, // Very small font
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showTourOverview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
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
                        Icons.list,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Tour Overview',
                        style: TextStyle(
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
              
              // PLACES LIST
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.places.length,
                  itemBuilder: (context, index) {
                    final place = widget.places[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          place['name'] ?? 'Unnamed Place',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place['address'] ?? 'No address',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (place['timeToSpend'] != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: .1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '⏱️ ${place['timeToSpend']} min',
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _selectPlace(index);
                        },
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LatLngBounds _calculateBounds() {
    if (widget.places.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(40.710428744293715, -8.626481451824), 
        northeast: const LatLng(40.710428744293715, -8.626481451824),
      );
    }

    double minLat = widget.places.first['latitude'];
    double maxLat = widget.places.first['latitude'];
    double minLng = widget.places.first['longitude'];
    double maxLng = widget.places.first['longitude'];

    for (final place in widget.places) {
      minLat = minLat < place['latitude'] ? minLat : place['latitude'];
      maxLat = maxLat > place['latitude'] ? maxLat : place['latitude'];
      minLng = minLng < place['longitude'] ? minLng : place['longitude'];
      maxLng = maxLng > place['longitude'] ? maxLng : place['longitude'];
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}