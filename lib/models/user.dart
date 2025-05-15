class User {
  String? id;
  String? name;
  String? email;
  String? profilePhoto;
  String? description;
  String? birthdate;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhoto,
    required this.description,
    required this.birthdate,
  });

  // Factory constructor to create a User from a JSON map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? "",
      email: json['email'] ?? "",
      name: json['name'] ?? "Unknown",
      profilePhoto: json['profilePhoto'] ?? "",
      description: json['description'] ?? "",
      birthdate: json['birthdate'] ?? "",
    );
  }

  // Method to convert a User object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profilePhoto': profilePhoto,
      'description': description,
      'birthdate': birthdate,
    };
  }
}

