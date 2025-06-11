import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/google_directions_service.dart';
import '../../../../models/tour_plan.dart';
import '../../../../models/place.dart';
import '../../../../models/user.dart';
import '../../domain/repositories/tour_repository.dart';
import '../../../bookings/presentation/widgets/book_tour_widget.dart';

class TourPreviewScreen extends StatefulWidget {
  final TourPlan tourPlan;
  final List<Place> places;
  final bool isExploreMode; // For explore screen - shows book button
  final bool hideActions; // For booking cards - hides all buttons

  const TourPreviewScreen({
    super.key,
    required this.tourPlan,
    required this.places,
    this.isExploreMode = false, // Default to false for backward compatibility
    this.hideActions = false, // Default to false - show buttons by default
  });

  @override
  State<TourPreviewScreen> createState() => _TourPreviewScreenState();
}

class _TourPreviewScreenState extends State<TourPreviewScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLngBounds? _mapBounds;
  bool _isLoadingRoute = false;
  double _totalDistance = 0.0;
  int _totalWalkingTime = 0;
  
  // Guide data for booking
  User? _guide;
  
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    
    _setupMapData();
    
    // Load guide data if in explore mode for better booking experience
    if (widget.isExploreMode) {
      _loadGuideData();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _setupMapData() {
    _createMarkers();
    _calculateRoute();
  }

  void _createMarkers() {
    final markers = <Marker>{};
    
    for (int i = 0; i < widget.places.length; i++) {
      final place = widget.places[i];
      final position = LatLng(place.location.latitude, place.location.longitude);
      
      markers.add(
        Marker(
          markerId: MarkerId('place_$i'),
          position: position,
          infoWindow: InfoWindow(
            title: '${i + 1}. ${place.name}',
            snippet: '${place.stayingDuration} min • ${place.address ?? 'Location'}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 
                ? BitmapDescriptor.hueGreen  // Start point
                : i == widget.places.length - 1 
                    ? BitmapDescriptor.hueRed  // End point
                    : BitmapDescriptor.hueOrange,  // Intermediate points
          ),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
    
    _calculateMapBounds();
  }

  void _calculateMapBounds() {
    if (widget.places.isEmpty) return;
    
    double minLat = widget.places.first.location.latitude;
    double maxLat = widget.places.first.location.latitude;
    double minLng = widget.places.first.location.longitude;
    double maxLng = widget.places.first.location.longitude;
    
    for (final place in widget.places) {
      minLat = min(minLat, place.location.latitude);
      maxLat = max(maxLat, place.location.latitude);
      minLng = min(minLng, place.location.longitude);
      maxLng = max(maxLng, place.location.longitude);
    }
    
    // Add some padding
    const double padding = 0.005;
    _mapBounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  Future<void> _calculateRoute() async {
    if (widget.places.length < 2) return;
    
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final polylines = <Polyline>{};
      double totalDistance = 0.0;
      int totalWalkingTime = 0;
      int totalTimeAtPlaces = 0;

      // Calculate walking routes between consecutive places using Google Directions API
      for (int i = 0; i < widget.places.length - 1; i++) {
        final startPlace = widget.places[i];
        final endPlace = widget.places[i + 1];
        
        final startPoint = LatLng(startPlace.location.latitude, startPlace.location.longitude);
        final endPoint = LatLng(endPlace.location.latitude, endPlace.location.longitude);
        
        // Try to get walking directions from Google Directions API
        final directionsResult = await GoogleDirectionsService.getWalkingDirections(
          origin: startPoint,
          destination: endPoint,
        );

        List<LatLng> routeCoordinates;
        double segmentDistance;
        int segmentWalkingTime;

        if (directionsResult != null && directionsResult.polylinePoints.isNotEmpty) {
          // Use Google Directions API data
          routeCoordinates = directionsResult.polylinePoints;
          segmentDistance = directionsResult.distanceValue; // km
          segmentWalkingTime = directionsResult.durationValue.round(); // minutes
          
          print('✅ Google Directions: ${segmentDistance.toStringAsFixed(2)} km, ${segmentWalkingTime} min walking');
        } else {
          // Fallback to straight line if API fails
          routeCoordinates = [startPoint, endPoint];
          segmentDistance = Geolocator.distanceBetween(
            startPlace.location.latitude,
            startPlace.location.longitude,
            endPlace.location.latitude,
            endPlace.location.longitude,
          ) / 1000; // Convert to kilometers
          
          // Estimate walking time (average 5 km/h)
          segmentWalkingTime = (segmentDistance / 5 * 60).round(); // minutes
          
          print('⚠️ Fallback to straight line: ${segmentDistance.toStringAsFixed(2)} km, ${segmentWalkingTime} min walking');
        }

        totalDistance += segmentDistance;
        totalWalkingTime += segmentWalkingTime;
        
        // Create polyline for this segment
        polylines.add(
          Polyline(
            polylineId: PolylineId('route_$i'),
            points: routeCoordinates,
            color: AppColors.primary,
            width: 5,
            patterns: i == 0 ? [] : [PatternItem.dash(20), PatternItem.gap(10)],
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
          ),
        );

        // Add a small delay between API calls to avoid rate limiting
        if (i < widget.places.length - 2) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      
      // Add time spent at each place
      for (final place in widget.places) {
        totalTimeAtPlaces += place.stayingDuration;
      }

      // Update map bounds to include all route points if we have them
      if (totalDistance > 0) {
        _updateMapBoundsWithRoute(totalDistance);
      }

      setState(() {
        _polylines = polylines;
        _totalDistance = totalDistance;
        _totalWalkingTime = totalWalkingTime + totalTimeAtPlaces;
        _isLoadingRoute = false;
      });

      print('🎯 Total tour: ${totalDistance.toStringAsFixed(2)} km, ${totalWalkingTime} min walking + ${totalTimeAtPlaces} min at places = ${totalWalkingTime + totalTimeAtPlaces} min total');
      
    } catch (e) {
      print('Error calculating route: $e');
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _updateMapBoundsWithRoute(double totalDistance) {
    if (widget.places.isEmpty) return;
    
    double minLat = widget.places.first.location.latitude;
    double maxLat = widget.places.first.location.latitude;
    double minLng = widget.places.first.location.longitude;
    double maxLng = widget.places.first.location.longitude;
    
    for (final place in widget.places) {
      minLat = min(minLat, place.location.latitude);
      maxLat = max(maxLat, place.location.latitude);
      minLng = min(minLng, place.location.longitude);
      maxLng = max(maxLng, place.location.longitude);
    }
    
    // Add some padding
    const double padding = 0.002;
    _mapBounds = LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  void _fitMapToRoute() {
    if (_mapController != null && _mapBounds != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(_mapBounds!, 100.0),
      );
    }
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Future<void> _publishTour() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );

      // Check if tour is ready to be published
      if (!widget.tourPlan.isReadyToPublish) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tour cannot be published yet. Please ensure you have:\n'
              '• At least 2 places\n'
              '• A title\n'
              '• A description',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Update tour status to published
      final tourRepository = context.read<TourRepository>();
      final updatedTour = widget.tourPlan.copyWith(
        status: TourStatus.published,
        updatedAt: Timestamp.now(),
      );

      await tourRepository.updateTour(updatedTour);

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tour published successfully! 🎉\nTravelers can now discover and book your tour.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      // Navigate back with 'published' result
      Navigator.pop(context, 'published');

    } catch (e) {
      // Close loading dialog if still open
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Failed to publish tour: ${e.toString()}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _loadGuideData() async {
    if (widget.tourPlan.guideId.isEmpty) return;
    
    try {
      final guideDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.tourPlan.guideId)
          .get();
      
      if (guideDoc.exists) {
        setState(() {
          _guide = User.fromMap(guideDoc.data()!, guideDoc.id);
        });
      }
    } catch (e) {
      print('Error loading guide data: $e');
    }
  }

  void _showBookingFlow() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BookTourWidget(
          tour: widget.tourPlan,
          guide: _guide, // Pass the pre-loaded guide data for better performance
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Map
            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                // Fit map to show all places after a short delay
                Future.delayed(const Duration(milliseconds: 500), () {
                  _fitMapToRoute();
                });
              },
              initialCameraPosition: CameraPosition(
                target: widget.places.isNotEmpty
                    ? LatLng(
                        widget.places.first.location.latitude,
                        widget.places.first.location.longitude,
                      )
                    : const LatLng(40.6333, -8.6594), // Coimbra fallback
                zoom: 14.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            
            // Top Bar
            _buildTopBar(),
            
            // Bottom Info Card
            _buildBottomInfoCard(),
            
            // Loading Overlay
            if (_isLoadingRoute)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
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
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.3),
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
                    color: Colors.black.withOpacity(0.2),
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
            
            // Title
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.tourPlan.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tour Preview • ${widget.places.length} places',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Fit Map Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _fitMapToRoute,
                icon: const Icon(Icons.fit_screen, color: AppColors.primary),
                iconSize: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfoCard() {
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
              color: Colors.black.withOpacity(0.15),
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
            
            // Tour Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.route,
                    title: 'Distance',
                    value: '${_totalDistance.toStringAsFixed(1)} km',
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.access_time,
                    title: 'Total Time',
                    value: _formatDuration(_totalWalkingTime),
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.location_on,
                    title: 'Places',
                    value: '${widget.places.length}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Places List
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.places.length,
                itemBuilder: (context, index) {
                  final place = widget.places[index];
                  return _buildPlaceCard(place, index);
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            if (widget.hideActions) ...[
              // Do not show any buttons when hideActions is true
              const SizedBox.shrink(),
            ] else if (widget.isExploreMode) ...[
              // In explore mode, show the book tour button (reverted back to original)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showBookingFlow(),
                  icon: const Icon(Icons.book_online),
                  label: const Text('Book This Tour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              // In guide mode, show edit and publish buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, 'edit');
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Tour'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: widget.tourPlan.status == TourStatus.published
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Published',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: widget.tourPlan.isReadyToPublish 
                                ? () => _publishTour()
                                : null,
                            icon: Icon(
                              widget.tourPlan.isReadyToPublish 
                                  ? Icons.publish 
                                  : Icons.warning,
                            ),
                            label: Text(
                              widget.tourPlan.isReadyToPublish 
                                  ? 'Publish' 
                                  : 'Not Ready',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.tourPlan.isReadyToPublish 
                                  ? AppColors.primary 
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Place place, int index) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Place Image or Icon
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              color: AppColors.primary.withOpacity(0.1),
            ),
            child: place.photoUrl != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      place.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.location_on, color: AppColors.primary),
                    ),
                  )
                : const Icon(Icons.location_on, color: AppColors.primary, size: 32),
          ),
          
          // Place Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: index == 0 
                              ? Colors.green 
                              : index == widget.places.length - 1 
                                  ? Colors.red 
                                  : Colors.orange,
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
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${place.stayingDuration} min',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}