import 'package:cloud_firestore/cloud_firestore.dart';

class Destination {
  String? id;
  String? name;
  String? description;
  String? imageurl;
  double? latitude;
  double? longitude;
  int? order;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.imageurl,
    required this.latitude,
    required this.longitude,
    this.order, 
  });
  // Factory constructor to create a Destination from a JSON map
  factory Destination.fromJson(Map<String, dynamic> json) {

    final coordinates = json['coordinates'] as GeoPoint?;

    return Destination(
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      description: json['description'] ?? "",
      imageurl: json['imageurl'] ?? "",
      // latitude: (json['latitude'] as num?)?.toDouble(),
      // longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: coordinates?.latitude,
      longitude: coordinates?.longitude,
      order: json['order'],
    );
  }
  // Method to convert a Destination object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageurl': imageurl,
      'latitude': latitude,
      'longitude': longitude,
      'order': order,
    };
  }
}