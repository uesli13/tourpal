import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/map_preview_service.dart';

class EnhancedTourPreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  final Function(List<Map<String, dynamic>>) onLocationsUpdated;

  const EnhancedTourPreviewScreen({
    super.key,
    required this.locations,
    required this.onLocationsUpdated,
  });

  @override
  State<EnhancedTourPreviewScreen> createState() => _EnhancedTourPreviewScreenState();
}

class _EnhancedTourPreviewScreenState extends State<EnhancedTourPreviewScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int _totalDistance = 0;
  int _totalDuration = 0;
  List<Map<String, dynamic>> _segments = [];
  bool _isLoadingRoute = true;
  int? _selectedLocationIndex;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadRouteData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> _loadRouteData() async {
    try {
      final routeData = await MapPreviewService.generateTourRoute(widget.locations);
      
      if (mounted) {
        setState(() {
          _markers = routeData['markers'];
          _polylines = routeData['polylines'];
          _totalDistance = routeData['totalDistance'];
          _totalDuration = routeData['totalDuration'];
          _segments = routeData['segments'];
          _isLoadingRoute = false;
        });
        
        _fadeController.forward();
        _slideController.forward();
        _fitMapToRoute();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Could not load route directions'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _fitMapToRoute() {
    if (_mapController != null && widget.locations.isNotEmpty) {
      final bounds = MapPreviewService.getBoundsFromLocations(widget.locations);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  void _selectLocation(int index) {
    setState(() {
      _selectedLocationIndex = _selectedLocationIndex == index ? null : index;
    });
    
    if (_selectedLocationIndex != null) {
      final location = widget.locations[_selectedLocationIndex!];
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location['latitude'], location['longitude']),
          16.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Tour Route Preview',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showRouteOptions,
            icon: const Icon(Icons.more_vert),
            tooltip: 'Route Options',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildRouteStatsCard(),
          _buildMapSection(),
          _buildLocationsList(),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildRouteStatsCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: .8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _isLoadingRoute
            ? const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Calculating optimal route...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildStatColumn(
                      icon: Icons.location_on,
                      label: 'Stops',
                      value: '${widget.locations.length}',
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withValues(alpha: .3),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      icon: Icons.straighten,
                      label: 'Distance',
                      value: MapPreviewService.formatDistance(_totalDistance),
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withValues(alpha: .3),
                  ),
                  Expanded(
                    child: _buildStatColumn(
                      icon: Icons.access_time,
                      label: 'Walking Time',
                      value: MapPreviewService.formatDuration(_totalDuration),
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: .9),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Expanded(
      flex: 3,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                _fitMapToRoute();
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              buildingsEnabled: true,
              trafficEnabled: false,
              initialCameraPosition: const CameraPosition(
                target: LatLng(40.6306, -8.6588),
                zoom: 14.0,
              ),
              onTap: (_) {
                if (_selectedLocationIndex != null) {
                  setState(() => _selectedLocationIndex = null);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationsList() {
    return Expanded(
      flex: 2,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .1),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.route,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Tour Route',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (_segments.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_segments.length} segments',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: widget.locations.length,
                  itemBuilder: (context, index) {
                    return _buildLocationCard(index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(int index) {
    final location = widget.locations[index];
    final isSelected = _selectedLocationIndex == index;
    final isFirst = index == 0;
    final isLast = index == widget.locations.length - 1;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: .05) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _selectLocation(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Route indicator
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isFirst
                          ? Colors.green
                          : isLast
                              ? Colors.red
                              : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isFirst ? Colors.green : isLast ? Colors.red : AppColors.primary)
                              .withValues(alpha: .3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: 3,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: .6),
                            AppColors.primary.withValues(alpha: .2),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 16),
              
              // Location photo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: location['photo'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(location['photo']),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.location_on,
                        color: isSelected ? AppColors.primary : Colors.grey,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              
              // Location info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location['name'] ?? 'Unknown Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location['address'] ?? 'No address available',
                      style: TextStyle(
                        color: isSelected ? AppColors.primary.withValues(alpha: .7) : AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isLast && index < _segments.length) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk,
                            size: 14,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${MapPreviewService.formatDuration(_segments[index]['duration'])} • ${MapPreviewService.formatDistance(_segments[index]['distance'])}',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Expand indicator
              AnimatedRotation(
                turns: isSelected ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit, color: AppColors.primary),
                label: const Text(
                  'Edit Route',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _confirmRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.check_circle),
                label: const Text(
                  'Confirm Route',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRouteOptions() {
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
              'Route Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Route'),
              onTap: () {
                Navigator.pop(context);
                _shareRoute();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Route'),
              onTap: () {
                Navigator.pop(context);
                _exportRoute();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Recalculate Route'),
              onTap: () {
                Navigator.pop(context);
                _recalculateRoute();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _shareRoute() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔗 Route sharing coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportRoute() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📥 Route export coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _recalculateRoute() {
    setState(() {
      _isLoadingRoute = true;
      _selectedLocationIndex = null;
    });
    _loadRouteData();
  }

  void _confirmRoute() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Route confirmed with ${widget.locations.length} locations',
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}