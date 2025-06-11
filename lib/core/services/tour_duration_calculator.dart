import 'dart:math';
import '../../models/place.dart';

class TourDurationCalculator {
  // Average walking speed in km/h
  static const double _averageWalkingSpeedKmh = 5.0;
  
  /// Calculate the total duration of a tour in hours
  /// This includes walking time between places + time spent at each place
  static Future<double> calculateTotalDuration(List<Place> places) async {
    if (places.isEmpty) return 0.0;
    
    // Calculate total staying time at all places (in minutes)
    int totalStayingTimeMinutes = places.fold(0, (sum, place) => sum + place.stayingDuration);
    
    // Calculate total walking time between places
    double totalWalkingTimeMinutes = 0.0;
    
    for (int i = 0; i < places.length - 1; i++) {
      double distanceKm = _calculateDistanceBetweenPlaces(places[i], places[i + 1]);
      double walkingTimeMinutes = (distanceKm / _averageWalkingSpeedKmh) * 60;
      totalWalkingTimeMinutes += walkingTimeMinutes;
    }
    
    // Convert total time from minutes to hours
    double totalTimeHours = (totalStayingTimeMinutes + totalWalkingTimeMinutes) / 60;
    
    // Round to 1 decimal place
    return double.parse(totalTimeHours.toStringAsFixed(1));
  }
  
  /// Calculate distance between two places using Haversine formula
  static double _calculateDistanceBetweenPlaces(Place place1, Place place2) {
    const double earthRadiusKm = 6371.0;
    
    double lat1Rad = _degreesToRadians(place1.location.latitude);
    double lat2Rad = _degreesToRadians(place2.location.latitude);
    double deltaLatRad = _degreesToRadians(place2.location.latitude - place1.location.latitude);
    double deltaLonRad = _degreesToRadians(place2.location.longitude - place1.location.longitude);
    
    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }
  
  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
  
  /// Get breakdown of tour duration components
  static Future<Map<String, dynamic>> getDurationBreakdown(List<Place> places) async {
    if (places.isEmpty) {
      return {
        'totalHours': 0.0,
        'stayingTimeMinutes': 0,
        'walkingTimeMinutes': 0.0,
        'numberOfPlaces': 0,
      };
    }
    
    // Calculate total staying time at all places (in minutes)
    int totalStayingTimeMinutes = places.fold(0, (sum, place) => sum + place.stayingDuration);
    
    // Calculate total walking time between places
    double totalWalkingTimeMinutes = 0.0;
    
    for (int i = 0; i < places.length - 1; i++) {
      double distanceKm = _calculateDistanceBetweenPlaces(places[i], places[i + 1]);
      double walkingTimeMinutes = (distanceKm / _averageWalkingSpeedKmh) * 60;
      totalWalkingTimeMinutes += walkingTimeMinutes;
    }
    
    return {
      'totalHours': double.parse(((totalStayingTimeMinutes + totalWalkingTimeMinutes) / 60).toStringAsFixed(1)),
      'stayingTimeMinutes': totalStayingTimeMinutes,
      'walkingTimeMinutes': double.parse(totalWalkingTimeMinutes.toStringAsFixed(1)),
      'numberOfPlaces': places.length,
    };
  }
}