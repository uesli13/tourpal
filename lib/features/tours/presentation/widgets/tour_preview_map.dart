import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';

class TourPreviewMap extends StatefulWidget {
  final List<Map<String, dynamic>> places;

  const TourPreviewMap({
    super.key,
    required this.places,
  });

  @override
  State<TourPreviewMap> createState() => _TourPreviewMapState();
}

class _TourPreviewMapState extends State<TourPreviewMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Default location (San Francisco) if no places with coordinates
  static const LatLng _defaultLocation = LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    _createMarkersAndPolylines();
  }

  @override
  void didUpdateWidget(TourPreviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places) {
      _createMarkersAndPolylines();
    }
  }

  void _createMarkersAndPolylines() {
    _markers.clear();
    _polylines.clear();

    if (widget.places.isEmpty) return;

    List<LatLng> routePoints = [];

    // Create markers for each place
    for (int i = 0; i < widget.places.length; i++) {
      final place = widget.places[i];
      final location = place['location'];
      
      // Handle GeoPoint or default location
      LatLng latLng;
      if (location is GeoPoint) {
        latLng = LatLng(location.latitude, location.longitude);
      } else {
        latLng = _defaultLocation;
      }
      
      routePoints.add(latLng);
      
      _markers.add(
        Marker(
          markerId: MarkerId('place_${place['id']}'),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 
                ? BitmapDescriptor.hueGreen // Start point
                : i == widget.places.length - 1
                    ? BitmapDescriptor.hueRed // End point
                    : BitmapDescriptor.hueBlue, // Intermediate points
          ),
          infoWindow: InfoWindow(
            title: place['name'] ?? 'Place ${i + 1}',
            snippet: place['description'] ?? 'Stop ${i + 1}',
          ),
        ),
      );
    }

    // Create polyline connecting all points
    if (routePoints.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('tour_route'),
          points: routePoints,
          color: AppColors.primary,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.places.isEmpty) {
      return _buildEmptyMapState();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
          _fitMarkersInView();
        },
        initialCameraPosition: CameraPosition(
          target: _getInitialTarget(),
          zoom: 12.0,
        ),
        markers: _markers,
        polylines: _polylines,
        mapType: MapType.normal,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: false,
        mapToolbarEnabled: false,
        buildingsEnabled: true,
        tiltGesturesEnabled: false,
        rotateGesturesEnabled: false,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
      ),
    );
  }

  Widget _buildEmptyMapState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withValues(alpha: .3),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_outlined,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Map Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add places to see your tour route',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LatLng _getInitialTarget() {
    if (_markers.isNotEmpty) {
      final firstMarker = _markers.first;
      return firstMarker.position;
    }
    return _defaultLocation;
  }

  void _fitMarkersInView() {
    if (_markers.isEmpty || _mapController == null) return;

    if (_markers.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _markers.first.position,
            zoom: 15.0,
          ),
        ),
      );
      return;
    }

    // Calculate bounds to fit all markers
    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (final marker in _markers) {
      minLat = minLat < marker.position.latitude ? minLat : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude ? maxLat : marker.position.latitude;
      minLng = minLng < marker.position.longitude ? minLng : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude ? maxLng : marker.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}