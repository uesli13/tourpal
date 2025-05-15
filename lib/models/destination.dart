class Destination {
  String? id;
  String? name;
  String? description;
  String? image;
  double? latitude;
  double? longitude;

  Destination({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.latitude,
    required this.longitude,
  });
  // Factory constructor to create a Destination from a JSON map
  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] ?? "",
      name: json['name'] ?? "",
      description: json['description'] ?? "",
      image: json['image'] ?? "",
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
  // Method to convert a Destination object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}