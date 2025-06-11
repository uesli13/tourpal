import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationTrackingService {
  final StreamController<LatLng> _locationController = StreamController<LatLng>.broadcast();
  
  Stream<LatLng> get locationStream => _locationController.stream;
  
  // Simple constructor that doesn't require repository
  LocationTrackingService();

  Future<void> initialize() async {
    try {
      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied, we cannot request permissions.');
        return;
      }
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return;
      }
      
      print('Location permissions granted successfully');
    } catch (e) {
      print('Error initializing location service: $e');
    }
  }

  Future<LatLng> getCurrentLocation() async {
    try {
      // Ensure permissions are granted first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print('Location permission not granted');
        return const LatLng(37.4219999, -122.0840575); // Default to San Francisco
      }
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('Current location: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      // Return default location if GPS fails
      return const LatLng(37.4219999, -122.0840575); // San Francisco
    }
  }

  void startTracking() {
    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );
      
      Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          print('Location update: ${position.latitude}, ${position.longitude}');
          _locationController.add(LatLng(position.latitude, position.longitude));
        },
        onError: (error) {
          print('Location tracking error: $error');
        },
      );
    } catch (e) {
      print('Error starting location tracking: $e');
    }
  }

  void dispose() {
    _locationController.close();
  }
}