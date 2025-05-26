import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tourpal/core/constants/app_colors.dart';
import 'package:tourpal/core/constants/app_constants.dart';
import '../../../../core/services/map_preview_service.dart';

class TourRoutePreview extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final bool showRoute;
  final bool interactive;
  final double height;
  final VoidCallback? onMapTap;
  final Function(Map<String, dynamic>)? onLocationTap;

  const TourRoutePreview({
    super.key,
    required this.locations,
    this.showRoute = true,
    this.interactive = true,
    this.height = 300,
    this.onMapTap,
    this.onLocationTap,
  });

  @override
  State<TourRoutePreview> createState() => _TourRoutePreviewState();
}

class _TourRoutePreviewState extends State<TourRoutePreview> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  Map<String, dynamic>? _routeData;

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  @override
  void didUpdateWidget(TourRoutePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations) {
      _setupMapData();
    }
  }

  Future<void> _setupMapData() async {
    setState(() => _isLoading = true);
    
    if (widget.showRoute && widget.locations.length > 1) {
      _routeData = await MapPreviewService.generateTourRoute(widget.locations);
      if (_routeData != null) {
        setState(() {
          _markers = _routeData!['markers'];
          _polylines = _routeData!['polylines'];
        });
      }
    } else {
      setState(() {
        _markers = _generateBasicMarkers(widget.locations);
        _polylines = {};
      });
    }
    
    setState(() => _isLoading = false);
    
    // Fit map to show all locations
    if (_mapController != null && widget.locations.isNotEmpty) {
      _fitMapToLocations();
    }
  }

  Set<Marker> _generateBasicMarkers(List<Map<String, dynamic>> locations) {
    Set<Marker> markers = {};
    
    for (int i = 0; i < locations.length; i++) {
      final location = locations[i];
      markers.add(
        Marker(
          markerId: MarkerId('location_$i'),
          position: LatLng(location['latitude'], location['longitude']),
          infoWindow: InfoWindow(
            title: location['name'],
            snippet: location['address'],
          ),
          icon: i == 0
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
              : i == locations.length - 1
                  ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
                  : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    return markers;
  }

  void _fitMapToLocations() {
    if (_mapController != null && widget.locations.isNotEmpty) {
      double minLat = widget.locations.first['latitude'];
      double maxLat = widget.locations.first['latitude'];
      double minLng = widget.locations.first['longitude'];
      double maxLng = widget.locations.first['longitude'];

      for (final location in widget.locations) {
        if (location['latitude'] < minLat) minLat = location['latitude'];
        if (location['latitude'] > maxLat) maxLat = location['latitude'];
        if (location['longitude'] < minLng) minLng = location['longitude'];
        if (location['longitude'] > maxLng) maxLng = location['longitude'];
      }

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UIConstants.defaultBorderRadius),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (!_isLoading && widget.locations.isNotEmpty) {
                  _fitMapToLocations();
                }
              },
              markers: _markers,
              polylines: _polylines,
              onTap: widget.onMapTap != null 
                  ? (_) => widget.onMapTap!() 
                  : null,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: widget.interactive,
              mapToolbarEnabled: false,
              compassEnabled: false,
              scrollGesturesEnabled: widget.interactive,
              zoomGesturesEnabled: widget.interactive,
              rotateGesturesEnabled: widget.interactive,
              tiltGesturesEnabled: widget.interactive,
              initialCameraPosition: CameraPosition(
                target: widget.locations.isNotEmpty
                    ? LatLng(
                        widget.locations.first['latitude'],
                        widget.locations.first['longitude'],
                      )
                    : const LatLng(40.6306, -8.6588),
                zoom: 14.0,
              ),
            ),
            
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.white.withValues(alpha: .8),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            
            // Route info overlay (top-left)
            if (_routeData != null && !_isLoading)
              Positioned(
                top: 12,
                left: 12,
                child: _buildRouteInfoCard(),
              ),
            
            // Location count overlay (top-right)
            Positioned(
              top: 12,
              right: 12,
              child: _buildLocationCountCard(),
            ),
            
            // Interactive overlay (bottom)
            if (widget.onMapTap != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: _buildInteractiveCard(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    if (_routeData == null) return Container();
    
    final totalDistance = _routeData!['totalDistance'] as int;
    final totalDuration = _routeData!['totalDuration'] as int;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_walk,
            size: 16,
            color: Colors.green[600],
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDistance(totalDistance),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _formatDuration(totalDuration),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCountCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            '${widget.locations.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.touch_app,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tap to view full map',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  String _formatDistance(int meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// Full-screen map viewer
class FullScreenTourMap extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final Function(List<Map<String, dynamic>>)? onLocationsUpdated;

  const FullScreenTourMap({
    super.key,
    required this.locations,
    this.onLocationsUpdated,
  });

  @override
  State<FullScreenTourMap> createState() => _FullScreenTourMapState();
}

class _FullScreenTourMapState extends State<FullScreenTourMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Map<String, dynamic>? _routeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  Future<void> _setupMapData() async {
    setState(() => _isLoading = true);
    
    _routeData = await MapPreviewService.generateTourRoute(widget.locations);
    if (_routeData != null) {
      setState(() {
        _markers = _routeData!['markers'];
        _polylines = _routeData!['polylines'];
      });
    }
    
    setState(() => _isLoading = false);
    
    if (_mapController != null) {
      _fitMapToLocations();
    }
  }

  void _fitMapToLocations() {
    if (_mapController != null && widget.locations.isNotEmpty) {
      double minLat = widget.locations.first['latitude'];
      double maxLat = widget.locations.first['latitude'];
      double minLng = widget.locations.first['longitude'];
      double maxLng = widget.locations.first['longitude'];

      for (final location in widget.locations) {
        if (location['latitude'] < minLat) minLat = location['latitude'];
        if (location['latitude'] > maxLat) maxLat = location['latitude'];
        if (location['longitude'] < minLng) minLng = location['longitude'];
        if (location['longitude'] > maxLng) maxLng = location['longitude'];
      }

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Route'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_routeData != null)
            IconButton(
              onPressed: _showRouteDetails,
              icon: const Icon(Icons.info_outline),
              tooltip: 'Route Details',
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (!_isLoading) {
                _fitMapToLocations();
              }
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: true,
            initialCameraPosition: CameraPosition(
              target: widget.locations.isNotEmpty
                  ? LatLng(
                      widget.locations.first['latitude'],
                      widget.locations.first['longitude'],
                    )
                  : const LatLng(40.6306, -8.6588),
              zoom: 14.0,
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: .8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Route summary card
          if (_routeData != null && !_isLoading)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildRouteSummaryCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildRouteSummaryCard() {
    if (_routeData == null) return Container();
    
    final totalDistance = _routeData!['totalDistance'] as int;
    final totalDuration = _routeData!['totalDuration'] as int;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.directions_walk,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tour Route Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.locations.length} locations',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.straighten,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDistance(totalDistance),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(totalDuration),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRouteDetails() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildRouteDetailsSheet(),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Widget _buildRouteDetailsSheet() {
    if (_routeData == null || _routeData!['segments'] == null) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text('No route details available'),
        ),
      );
    }
    
    final segments = _routeData!['segments'] as List<Map<String, dynamic>>;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          const Text(
            'Route Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Segments list
          Expanded(
            child: ListView.builder(
              itemCount: segments.length,
              itemBuilder: (context, index) {
                final segment = segments[index];
                return _buildSegmentCard(segment, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentCard(Map<String, dynamic> segment, int index) {
    final fromLocation = segment['fromLocation'];
    final toLocation = segment['toLocation'];
    final distance = segment['distance'] as int;
    final duration = segment['duration'] as int;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fromLocation['name']} → ${toLocation['name']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDistance(distance),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDistance(int meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}