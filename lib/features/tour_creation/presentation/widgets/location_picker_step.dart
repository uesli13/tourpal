import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import 'full_screen_tour_map.dart';

class LocationPickerStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String, dynamic) onDataChanged;

  const LocationPickerStep({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<LocationPickerStep> createState() => _LocationPickerStepState();
}

class _LocationPickerStepState extends State<LocationPickerStep> {
  List<Map<String, dynamic>> _selectedLocations = [];

  @override
  void initState() {
    super.initState();
    _selectedLocations = List<Map<String, dynamic>>.from(
      widget.data['locations'] ?? []
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SECTION HEADER
          Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tour Locations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Add at least 2 locations to create your tour',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: .3)),
                ),
                child: Text(
                  '${_selectedLocations.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),

          // ADD LOCATION BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addLocation,
              icon: const Icon(Icons.add_location_alt, size: 20),
              label: const Text(
                'Add Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // TOUR PREVIEW MAP
          if (_selectedLocations.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: .05),
                    AppColors.secondary.withValues(alpha: .05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.route,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tour Preview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _openFullScreenMap,
                        icon: const Icon(Icons.fullscreen, size: 16),
                        label: const Text('Full View'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // MINI MAP PREVIEW
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            _selectedLocations.first['latitude'],
                            _selectedLocations.first['longitude'],
                          ),
                          zoom: 13,
                        ),
                        markers: _createMarkers(),
                        polylines: _createPolylines(),
                        onTap: (_) => _openFullScreenMap(),
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        scrollGesturesEnabled: false,
                        zoomGesturesEnabled: false,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                      ),
                    ),
                  ),
                  
                  if (_selectedLocations.length > 1) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatChip(
                          icon: Icons.location_on,
                          label: '${_selectedLocations.length} stops',
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _buildStatChip(
                          icon: Icons.directions_walk,
                          label: 'Walking route',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // LOCATIONS LIST
          if (_selectedLocations.isEmpty)
            _buildEmptyState()
          else
            _buildLocationsList(),
        ],
      ),
    );
  }

  Set<Marker> _createMarkers() {
    return _selectedLocations.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> location = entry.value;
      
      return Marker(
        markerId: MarkerId('location_$index'),
        position: LatLng(location['latitude'], location['longitude']),
        infoWindow: InfoWindow(
          title: location['name'] ?? 'Location ${index + 1}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          index == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue,
        ),
      );
    }).toSet();
  }

  Set<Polyline> _createPolylines() {
    if (_selectedLocations.length < 2) return {};
    
    List<LatLng> points = _selectedLocations
        .map((location) => LatLng(location['latitude'], location['longitude']))
        .toList();

    return {
      Polyline(
        polylineId: const PolylineId('tour_route'),
        points: points,
        color: AppColors.primary,
        width: 3,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: .3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: .3)),
            ),
            child: const Icon(
              Icons.add_location_alt,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No locations added yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start building your tour by adding amazing locations',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedLocations.length,
      onReorder: _reorderLocations,
      itemBuilder: (context, index) {
        final location = _selectedLocations[index];
        return _buildLocationCard(location, index);
      },
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location, int index) {
    return Container(
      key: ValueKey(location['id']),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // DRAG HANDLE
          Icon(
            Icons.drag_handle,
            color: Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          
          // ORDER NUMBER
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
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
          const SizedBox(width: 12),
          
          // LOCATION INFO
          Expanded(
            child: GestureDetector(
              onTap: () => _showLocationDetails(location, index),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location['name'] ?? 'Unnamed Location',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location['address'] ?? 'No address',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          // DELETE BUTTON
          IconButton(
            onPressed: () => _removeLocation(index),
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: .1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationDetails(Map<String, dynamic> location, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                location['name'] ?? 'Location Details',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location['photo'] != null) ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(location['photo']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (location['description'] != null && location['description'].isNotEmpty) ...[
              Text(
                'Description:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(location['description']),
              const SizedBox(height: 12),
            ],
            Text(
              'Address:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(location['address'] ?? 'No address available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editLocationDetails(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _reorderLocations(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedLocations.removeAt(oldIndex);
      _selectedLocations.insert(newIndex, item);
    });
    widget.onDataChanged('locations', _selectedLocations);
  }

  void _openFullScreenMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenTourMap(
          locations: _selectedLocations,
          onLocationsUpdated: (updatedLocations) {
            setState(() {
              _selectedLocations = updatedLocations;
            });
            widget.onDataChanged('locations', _selectedLocations);
          },
        ),
      ),
    );
  }

  void _addLocation() async {
    // Your existing add location implementation
    try {
      final permissionStatus = await Permission.location.request();
      
      if (!permissionStatus.isGranted) {
        _showSnackBar('🚫 Location permission is required', Colors.red);
        return;
      }

      _showLoadingDialog();

      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
            ),
        );
      } catch (e) {
        currentPosition = Position(
          latitude: 38.7223,
          longitude: -9.1393,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      Navigator.of(context).pop(); // Close loading

      final result = await _showLocationPickerDialog(currentPosition);
      
      if (result != null) {
        setState(() {
          _selectedLocations.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'name': result['name'] ?? 'New Location',
            'address': result['address'] ?? 'Unknown Address',
            'latitude': result['latitude'],
            'longitude': result['longitude'],
            'description': result['description'] ?? '',
            'photo': null,
          });
        });
        
        widget.onDataChanged('locations', _selectedLocations);
        _showSnackBar('🎉 Added "${result['name']}" to your tour!', Colors.green);
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      _showSnackBar('❌ Error adding location: ${e.toString()}', Colors.red);
    }
  }

  void _editLocationDetails(int index) async {
    final location = _selectedLocations[index];
    final nameController = TextEditingController(text: location['name'] ?? '');
    final descriptionController = TextEditingController(text: location['description'] ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit_location, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Edit Location'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.of(context).pop({
                    'name': name,
                    'description': description,
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedLocations[index]['name'] = result['name']!;
        _selectedLocations[index]['description'] = result['description']!;
      });
      widget.onDataChanged('locations', _selectedLocations);
      _showSnackBar('✏️ Location updated!', AppColors.primary);
    }
  }

  void _removeLocation(int index) {
    final locationName = _selectedLocations[index]['name'];
    setState(() {
      _selectedLocations.removeAt(index);
    });
    widget.onDataChanged('locations', _selectedLocations);
    _showSnackBar('🗑️ Removed "$locationName"', Colors.red);
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _showLocationPickerDialog(Position initialPosition) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return EnhancedLocationPickerDialog(initialPosition: initialPosition);
      },
    );
  }
}

// Keep your existing EnhancedLocationPickerDialog class here...
class EnhancedLocationPickerDialog extends StatefulWidget {
  final Position initialPosition;

  const EnhancedLocationPickerDialog({
    super.key,
    required this.initialPosition,
  });

  @override
  State<EnhancedLocationPickerDialog> createState() => _EnhancedLocationPickerDialogState();
}

class _EnhancedLocationPickerDialogState extends State<EnhancedLocationPickerDialog> {
  late LatLng _selectedPosition;
  String _selectedAddress = '';
  bool _isLoadingAddress = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPosition = LatLng(
      widget.initialPosition.latitude,
      widget.initialPosition.longitude,
    );
    _getAddressFromCoordinates(_selectedPosition);
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
    });

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
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // HEADER
            Row(
              children: [
                const Icon(Icons.add_location_alt, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add New Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // MAP
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    onMapCreated: (controller) {
                    },
                    initialCameraPosition: CameraPosition(
                      target: _selectedPosition,
                      zoom: 15.0,
                    ),
                    onTap: (LatLng position) {
                      setState(() {
                        _selectedPosition = position;
                      });
                      _getAddressFromCoordinates(position);
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selectedPosition,
                      ),
                    },
                    myLocationEnabled: true,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // FORM
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Location Name *',
                hintText: 'Enter a name for this location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              onChanged: (value) => setState(() {}),
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add details about this location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _isLoadingAddress
                        ? const Text('Getting address...')
                        : Text(
                            _selectedAddress.isEmpty 
                                ? 'Tap on the map to select a location' 
                                : _selectedAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: _selectedAddress.isEmpty 
                                  ? Colors.grey[600] 
                                  : Colors.black87,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedAddress.isNotEmpty && _nameController.text.trim().isNotEmpty
                        ? () {
                            Navigator.of(context).pop({
                              'name': _nameController.text.trim(),
                              'description': _descriptionController.text.trim(),
                              'address': _selectedAddress,
                              'latitude': _selectedPosition.latitude,
                              'longitude': _selectedPosition.longitude,
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}