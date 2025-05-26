import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:polyline_codec/polyline_codec.dart';
import '../utils/logger.dart';

class MapPreviewService {
  static const String _googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // Add your API key here
  
  static Future<Map<String, dynamic>> generateTourRoute(List<Map<String, dynamic>> locations) async {
    if (locations.isEmpty) {
      return {
        'markers': <Marker>{},
        'polylines': <Polyline>{},
        'totalDistance': 0,
        'totalDuration': 0,
        'segments': <Map<String, dynamic>>[],
      };
    }

    Set<Marker> markers = {};
    Set<Polyline> polylines = {};
    List<Map<String, dynamic>> segments = [];
    int totalDistance = 0;
    int totalDuration = 0;

    // Create custom markers for each location
    for (int i = 0; i < locations.length; i++) {
      final location = locations[i];
      final position = LatLng(location['latitude'], location['longitude']);
      
      // Create custom marker icon based on category
      final markerIcon = await _createCustomMarker(
        location['category'] ?? 'custom',
        i + 1,
        i == 0 ? 'start' : i == locations.length - 1 ? 'end' : 'middle',
      );
      
      markers.add(
        Marker(
          markerId: MarkerId('location_$i'),
          position: position,
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: '${i + 1}. ${location['name']}',
            snippet: location['description'] ?? location['address'],
          ),
          onTap: () {
            // Handle marker tap if needed
          },
        ),
      );
    }

    // Create route segments with real path tracing
    for (int i = 0; i < locations.length - 1; i++) {
      try {
        final routeData = await _getWalkingDirections(
          LatLng(locations[i]['latitude'], locations[i]['longitude']),
          LatLng(locations[i + 1]['latitude'], locations[i + 1]['longitude']),
        );

        if (routeData != null) {
          // Add polyline for this segment with gradient colors
          final segmentColor = _getSegmentColor(i, locations.length - 1);
          
          polylines.add(
            Polyline(
              polylineId: PolylineId('route_segment_$i'),
              points: routeData['points'],
              color: segmentColor,
              width: 5,
              patterns: [PatternItem.dot, PatternItem.gap(10)],
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              geodesic: true,
            ),
          );

          totalDistance += (routeData['distance'] as num).toInt();
          totalDuration += (routeData['duration'] as num).toInt();
          
          segments.add({
            'fromLocation': locations[i],
            'toLocation': locations[i + 1],
            'distance': routeData['distance'],
            'duration': routeData['duration'],
            'instructions': routeData['instructions'],
            'points': routeData['points'],
          });
        }
      } catch (e) {
        AppLogger.error('Error getting directions for segment $i: $e');
        // Fallback to straight line
        final fallbackSegment = _createFallbackSegment(locations[i], locations[i + 1], i);
        polylines.add(fallbackSegment['polyline']);
        segments.add(fallbackSegment['segment']);
        totalDistance += (fallbackSegment['distance'] as num).toInt();
        totalDuration += (fallbackSegment['duration'] as num).toInt();
      }
    }

    return {
      'markers': markers,
      'polylines': polylines,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'segments': segments,
    };
  }

  static Future<BitmapDescriptor> _createCustomMarker(
    String category,
    int number,
    String type,
  ) async {
    // For now, use default markers with different colors
    // You can implement custom marker creation here
    switch (type) {
      case 'start':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      case 'end':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      default:
        return BitmapDescriptor.defaultMarkerWithHue(_getCategoryHue(category));
    }
  }

  static double _getCategoryHue(String category) {
    switch (category) {
      case 'restaurant':
        return BitmapDescriptor.hueOrange;
      case 'attraction':
        return BitmapDescriptor.hueBlue;
      case 'museum':
        return BitmapDescriptor.hueViolet;
      case 'park':
        return BitmapDescriptor.hueGreen;
      case 'shopping':
        return BitmapDescriptor.hueMagenta;
      case 'nightlife':
        return BitmapDescriptor.hueRose;
      case 'historical':
        return BitmapDescriptor.hueYellow;
      case 'religious':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  static Color _getSegmentColor(int segmentIndex, int totalSegments) {
    if (totalSegments <= 1) return Colors.blue;
    
    // Create gradient from green to red
    final ratio = segmentIndex / (totalSegments - 1);
    return Color.lerp(Colors.green, Colors.red, ratio) ?? Colors.blue;
  }

  static Future<Map<String, dynamic>?> _getWalkingDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    if (_googleMapsApiKey == 'YOUR_GOOGLE_MAPS_API_KEY') {
      // Fallback to estimated values if no API key
      return _createEstimatedRoute(origin, destination);
    }

    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}&'
        'destination=${destination.latitude},${destination.longitude}&'
        'mode=walking&'
        'alternatives=false&'
        'units=metric&'
        'key=$_googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Decode polyline points using static method
          final List<List<num>> decodedPoints = PolylineCodec.decode(
            route['overview_polyline']['points'],
          );
          
          final List<LatLng> polylineCoordinates = decodedPoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();

          return {
            'points': polylineCoordinates,
            'distance': leg['distance']['value'], // in meters
            'duration': leg['duration']['value'], // in seconds
            'instructions': _extractInstructions(leg['steps']),
          };
        } else {
          AppLogger.error('Directions API error: ${data['status']}');
          return _createEstimatedRoute(origin, destination);
        }
      } else {
        AppLogger.error('HTTP error: ${response.statusCode}');
        return _createEstimatedRoute(origin, destination);
      }
    } catch (e) {
      AppLogger.error('Error getting directions: $e');
      return _createEstimatedRoute(origin, destination);
    }
  }

  static Map<String, dynamic> _createEstimatedRoute(LatLng origin, LatLng destination) {
    // Create a simple curved path between two points
    final List<LatLng> points = _generateCurvedPath(origin, destination);
    final distance = _calculateDistance(origin, destination);
    final duration = (distance / 1.4).round(); // Assume 1.4 m/s walking speed
    
    return {
      'points': points,
      'distance': distance,
      'duration': duration,
      'instructions': ['Walk to destination'],
    };
  }

  static List<LatLng> _generateCurvedPath(LatLng start, LatLng end) {
    List<LatLng> points = [];
    const int numPoints = 20;
    
    for (int i = 0; i <= numPoints; i++) {
      final t = i / numPoints;
      
      // Add some randomness to make it look more natural
      final offset = sin(t * pi) * 0.001; // Small offset for curve
      
      final lat = start.latitude + (end.latitude - start.latitude) * t + offset;
      final lng = start.longitude + (end.longitude - start.longitude) * t + offset;
      
      points.add(LatLng(lat, lng));
    }
    
    return points;
  }

  static int _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double lat1Rad = start.latitude * pi / 180;
    final double lat2Rad = end.latitude * pi / 180;
    final double deltaLatRad = (end.latitude - start.latitude) * pi / 180;
    final double deltaLngRad = (end.longitude - start.longitude) * pi / 180;
    
    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return (earthRadius * c).round();
  }

  static Map<String, dynamic> _createFallbackSegment(
    Map<String, dynamic> fromLocation,
    Map<String, dynamic> toLocation,
    int segmentIndex,
  ) {
    final origin = LatLng(fromLocation['latitude'], fromLocation['longitude']);
    final destination = LatLng(toLocation['latitude'], toLocation['longitude']);
    
    final points = _generateCurvedPath(origin, destination);
    final distance = _calculateDistance(origin, destination);
    final duration = (distance / 1.4).round();
    
    return {
      'polyline': Polyline(
        polylineId: PolylineId('fallback_segment_$segmentIndex'),
        points: points,
        color: _getSegmentColor(segmentIndex, 10),
        width: 4,
        patterns: [PatternItem.dash(10), PatternItem.gap(5)],
      ),
      'segment': {
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'distance': distance,
        'duration': duration,
        'instructions': ['Walk to ${toLocation['name']}'],
      },
      'distance': distance,
      'duration': duration,
    };
  }

  static List<String> _extractInstructions(List<dynamic> steps) {
    return steps.map((step) {
      String instruction = step['html_instructions'] ?? '';
      // Remove HTML tags
      instruction = instruction.replaceAll(RegExp(r'<[^>]*>'), '');
      return instruction;
    }).toList();
  }

  static LatLngBounds getBoundsFromLocations(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(40.6306, -8.6588),
        northeast: const LatLng(40.6306, -8.6588),
      );
    }

    double minLat = locations.first['latitude'];
    double maxLat = locations.first['latitude'];
    double minLng = locations.first['longitude'];
    double maxLng = locations.first['longitude'];

    for (final location in locations) {
      if (location['latitude'] < minLat) minLat = location['latitude'];
      if (location['latitude'] > maxLat) maxLat = location['latitude'];
      if (location['longitude'] < minLng) minLng = location['longitude'];
      if (location['longitude'] > maxLng) maxLng = location['longitude'];
    }

    // Add some padding
    const padding = 0.001;
    return LatLngBounds(
      southwest: LatLng(minLat - padding, minLng - padding),
      northeast: LatLng(maxLat + padding, maxLng + padding),
    );
  }

  static String formatDistance(int meters) {
    if (meters < 1000) {
      return '${meters}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  static String formatDuration(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }
}