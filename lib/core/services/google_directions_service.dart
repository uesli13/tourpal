import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../utils/logger.dart';

class GoogleDirectionsService {
  static final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';

  /// Get walking directions between two points
  static Future<DirectionsResult?> getWalkingDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (_apiKey.isEmpty) {
      AppLogger.error('❌ GoogleDirectionsService: API key not found in .env file');
      return null;
    }

    AppLogger.info('🚶 GoogleDirectionsService: Getting walking directions from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}');

    try {
      final String url = '$_baseUrl'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=walking'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          AppLogger.info('✅ GoogleDirectionsService: Successfully retrieved walking directions');
          
          return DirectionsResult(
            polylinePoints: _decodePolyline(route['overview_polyline']['points']),
            distance: _parseDistance(leg['distance']['text']),
            duration: _parseDuration(leg['duration']['text']),
            distanceValue: leg['distance']['value'] / 1000.0, // Convert to km
            durationValue: leg['duration']['value'] / 60, // Convert to minutes
          );
        } else {
          AppLogger.error('❌ GoogleDirectionsService: API error - ${data['status']}');
          return null;
        }
      } else {
        AppLogger.error('❌ GoogleDirectionsService: HTTP error ${response.statusCode}');
        return null;
      }
    } catch (e) {
      AppLogger.error('💥 GoogleDirectionsService: Exception getting directions', e);
      return null;
    }
  }

  /// Decode polyline points from Google Directions API
  static List<LatLng> _decodePolyline(String encoded) {
    final polylinePoints = PolylinePoints();
    final List<PointLatLng> points = polylinePoints.decodePolyline(encoded);
    return points.map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  /// Parse distance string to double (e.g., "1.2 km" -> 1.2)
  static double _parseDistance(String distanceText) {
    final RegExp regex = RegExp(r'([\d.]+)');
    final match = regex.firstMatch(distanceText);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    return 0.0;
  }

  /// Parse duration string to int (e.g., "15 mins" -> 15)
  static int _parseDuration(String durationText) {
    final RegExp regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(durationText);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0;
  }
}

class DirectionsResult {
  final List<LatLng> polylinePoints;
  final double distance; // Parsed from text
  final int duration; // Parsed from text
  final double distanceValue; // Precise value in km
  final double durationValue; // Precise value in minutes

  DirectionsResult({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.distanceValue,
    required this.durationValue,
  });
}