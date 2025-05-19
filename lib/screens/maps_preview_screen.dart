import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/destination.dart';
import '../utils/constants.dart';

class MapsPreviewScreen extends StatefulWidget {
  final List<Destination> destinations;

  const MapsPreviewScreen({Key? key, required this.destinations}) : super(key: key);

  @override
  State<MapsPreviewScreen> createState() => _MapsPreviewScreenState();
}

class _MapsPreviewScreenState extends State<MapsPreviewScreen> {
  CameraPosition? _initialCamera;
  final Set<Marker> _markers = {};
  bool _loading = true;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _setupMap();
  }




LatLngBounds boundsFromMarkers(Set<Marker> markers) {
  final latitudes = markers.map((m) => m.position.latitude);
  final longitudes = markers.map((m) => m.position.longitude);

  final southwest = LatLng(latitudes.reduce((a, b) => a < b ? a : b),
                           longitudes.reduce((a, b) => a < b ? a : b));
  final northeast = LatLng(latitudes.reduce((a, b) => a > b ? a : b),
                           longitudes.reduce((a, b) => a > b ? a : b));

  return LatLngBounds(southwest: southwest, northeast: northeast);
}

  Future<void> _setupMap() async {
    // Request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    // Get user location
    Position userPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    // Add destination markers
    for (var dest in widget.destinations) {
      if (dest.latitude != null && dest.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(dest.id ?? UniqueKey().toString()),
            position: LatLng(dest.latitude!, dest.longitude!),
            infoWindow: InfoWindow(
              title: "${dest.order}. ${dest.name}",
              // snippet: dest.description,
            ),
          ),
        );
      }
    }

    // Determine initial camera to fit all markers
    // For simplicity, center on user
    _initialCamera = CameraPosition(
      target: LatLng(userPos.latitude, userPos.longitude),
      zoom: 12,
    );

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Map Preview'),
      ),
      body: _loading || _initialCamera == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: _initialCamera!,
              markers: _markers,
              myLocationEnabled: true,
              // onMapCreated: (controller) => _mapController = controller,
              onMapCreated: (controller) {
                _mapController = controller;

                if (_markers.length > 1) {
                  final bounds = boundsFromMarkers(_markers);
                  _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
                }
              },

            ),
    );
  }
}
