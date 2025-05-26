/// Place category enumeration following Tourpal development rules
enum PlaceCategory {
  restaurant('Restaurant'),
  attraction('Attraction'),
  museum('Museum'),
  park('Park'),
  beach('Beach'),
  monument('Monument'),
  church('Church'),
  market('Market'),
  shopping('Shopping'),
  hotel('Hotel'),
  cafe('Cafe'),
  bar('Bar'),
  theater('Theater'),
  gallery('Gallery'),
  library('Library'),
  hospital('Hospital'),
  school('School'),
  university('University'),
  stadium('Stadium'),
  airport('Airport'),
  trainStation('Train Station'),
  busStation('Bus Station'),
  pharmacy('Pharmacy'),
  bank('Bank'),
  postOffice('Post Office'),
  gasStation('Gas Station'),
  parking('Parking'),
  viewpoint('Viewpoint'),
  hiking('Hiking Trail'),
  beach_club('Beach Club'),
  spa('Spa'),
  gym('Gym'),
  cinema('Cinema'),
  nightclub('Nightclub'),
  casino('Casino'),
  zoo('Zoo'),
  aquarium('Aquarium'),
  botanical_garden('Botanical Garden'),
  archaeological_site('Archaeological Site'),
  historical_site('Historical Site'),
  religious_site('Religious Site'),
  cultural_center('Cultural Center'),
  conference_center('Conference Center'),
  entertainment('Entertainment'),
  outdoor_recreation('Outdoor Recreation'),
  water_sports('Water Sports'),
  adventure_sports('Adventure Sports'),
  wellness('Wellness'),
  education('Education'),
  transportation('Transportation'),
  services('Services'),
  accommodation('Accommodation'),
  food_and_drink('Food & Drink'),
  arts_and_culture('Arts & Culture'),
  nature_and_parks('Nature & Parks'),
  sports_and_fitness('Sports & Fitness'),
  shopping_and_retail('Shopping & Retail'),
  nightlife_and_entertainment('Nightlife & Entertainment'),
  health_and_medical('Health & Medical'),
  business_and_professional('Business & Professional'),
  government_and_public('Government & Public'),
  other('Other');

  const PlaceCategory(this.displayName);
  
  final String displayName;

  /// Get category from string value
  static PlaceCategory fromString(String value) {
    return PlaceCategory.values.firstWhere(
      (category) => category.name.toLowerCase() == value.toLowerCase(),
      orElse: () => PlaceCategory.other,
    );
  }

  /// Get main category groups
  static List<PlaceCategory> get mainCategories => [
    PlaceCategory.restaurant,
    PlaceCategory.attraction,
    PlaceCategory.museum,
    PlaceCategory.park,
    PlaceCategory.beach,
    PlaceCategory.monument,
    PlaceCategory.shopping,
    PlaceCategory.hotel,
    PlaceCategory.entertainment,
    PlaceCategory.nature_and_parks,
    PlaceCategory.arts_and_culture,
  ];

  /// Get all category names as strings
  static List<String> get categoryNames => 
      PlaceCategory.values.map((e) => e.displayName).toList();

  /// Check if this is a tourism-related category
  bool get isTourismRelated {
    return [
      PlaceCategory.attraction,
      PlaceCategory.museum,
      PlaceCategory.monument,
      PlaceCategory.park,
      PlaceCategory.beach,
      PlaceCategory.viewpoint,
      PlaceCategory.archaeological_site,
      PlaceCategory.historical_site,
      PlaceCategory.cultural_center,
      PlaceCategory.arts_and_culture,
      PlaceCategory.nature_and_parks,
    ].contains(this);
  }

  @override
  String toString() => displayName;
}