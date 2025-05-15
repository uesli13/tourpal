import 'destination.dart';

class TourPlan{
  String? id;
  String? title;
  String? description;
  String? city;
  String? createdAt;
  String? creatorId;
  String? image;
  List <Destination>? destinations;

  TourPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.city,
    required this.createdAt,
    required this.creatorId,
    required this.image,
    required this.destinations,
  });
  // Factory constructor to create a TourPlan from a JSON map
  factory TourPlan.fromJson(Map<String, dynamic> json) {
    return TourPlan(
      id: json['id'] ?? "",
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      city: json['city'] ?? "",
      createdAt: json['createdAt'] ?? "",
      creatorId: json['creatorId'] ?? "",
      image: json['image'] ?? "",
      destinations: (json['destinations'] as List<dynamic>?)
          ?.map((e) => Destination.fromJson(e))
          .toList(),
    );
  }
  // Method to convert a TourPlan object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'city': city,
      'createdAt': createdAt,
      'creatorId': creatorId,
      'image': image,
      'destinations': destinations?.map((e) => e.toJson()).toList(),
    };
  }
}