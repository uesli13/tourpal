import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String name;
  final GeoPoint location;
  final int? order;
  final String? address;
  final String? description;
  final String? photoUrl;
  final int stayingDuration;

  Place({
    required this.id,
    required this.name,
    required this.location,
    this.order,
    this.address,
    this.description,
    this.photoUrl,
    this.stayingDuration = 5,
  });

  factory Place.fromMap(Map<String, dynamic> map, String documentId) {
    return Place(
      id: documentId,
      name: map['name'] as String,
      location: map['location'] as GeoPoint,
      order: map['order'] as int?,
      address: map['address'] as String?,
      description: map['description'] as String?,
      photoUrl: map['photoUrl'] as String?,
      stayingDuration: map['stayingDuration'] as int? ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'order': order,
      'address': address,
      'description': description,
      'photoUrl': photoUrl,
      'stayingDuration': stayingDuration,
    };
  }

  Place copyWith({
    String? id,
    String? name,
    GeoPoint? location,
    int? order,
    String? address,
    String? description,
    String? photoUrl,
    int? stayingDuration,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      order: order ?? this.order,
      address: address ?? this.address,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      stayingDuration: stayingDuration ?? this.stayingDuration,
    );
  }

  // Helper methods for image management
  bool get hasImage => photoUrl != null && photoUrl!.isNotEmpty;
}