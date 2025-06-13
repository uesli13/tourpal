import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/utils/logger.dart';

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
          AppLogger.logInfo('Location permissions are denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        AppLogger.logInfo('Location permissions are permanently denied, we cannot request permissions.');
        return;
      }
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.logInfo('Location services are disabled.');
        return;
      }
      
      AppLogger.logInfo('Location permissions granted successfully');
    } catch (e) {
      AppLogger.logInfo('Error initializing location service: $e');
    }
  }

  Future<LatLng> getCurrentLocation() async {
    try {
      // Ensure permissions are granted first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        AppLogger.logInfo('Location permission not granted');
        return const LatLng(37.4219999, -122.0840575); // Default to San Francisco
      }
      
      Position position = await Geolocator.getCurrentPosition(
        // DEPRECATED: desiredAccuracy: LocationAccuracy.high,
        // DEPRECATED: timeLimit: const Duration(seconds: 10),
      );
      
      AppLogger.logInfo('Current location: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      AppLogger.logInfo('Error getting current location: $e');
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
          AppLogger.logInfo('Location update: ${position.latitude}, ${position.longitude}');
          _locationController.add(LatLng(position.latitude, position.longitude));
        },
        onError: (error) {
          AppLogger.logInfo('Location tracking error: $error');
        },
      );
    } catch (e) {
      AppLogger.logInfo('Error starting location tracking: $e');
    }
  }

  void dispose() {
    _locationController.close();
  }
}