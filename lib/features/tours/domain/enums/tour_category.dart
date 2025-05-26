/// Tour category enumeration following Tourpal development rules
enum TourCategory {
  adventure('Adventure', '🏔️'),
  cultural('Cultural', '🏛️'),
  food('Food & Drink', '🍽️'),
  historical('Historical', '🏰'),
  nature('Nature', '🌲'),
  urban('Urban', '🏙️'),
  beach('Beach', '🏖️'),
  mountain('Mountain', '⛰️'),
  religious('Religious', '⛪'),
  shopping('Shopping', '🛍️'),
  nightlife('Nightlife', '🌃'),
  sports('Sports', '⚽'),
  photography('Photography', '📸'),
  educational('Educational', '📚'),
  family('Family', '👨‍👩‍👧‍👦'),
  romantic('Romantic', '💕'),
  luxury('Luxury', '💎'),
  budget('Budget', '💰');

  const TourCategory(this.displayName, this.emoji);
  
  final String displayName;
  final String emoji;

  /// Parse category from string value
  static TourCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'adventure':
        return TourCategory.adventure;
      case 'cultural':
        return TourCategory.cultural;
      case 'nature':
        return TourCategory.nature;
      case 'food':
        return TourCategory.food;
      case 'historical':
        return TourCategory.historical;
      case 'urban':
        return TourCategory.urban;
      case 'beach':
        return TourCategory.beach;
      case 'mountain':
        return TourCategory.mountain;
      case 'religious':
        return TourCategory.religious;
      case 'shopping':
        return TourCategory.shopping;
      case 'nightlife':
        return TourCategory.nightlife;
      case 'sports':
        return TourCategory.sports;
      case 'photography':
        return TourCategory.photography;
      case 'educational':
        return TourCategory.educational;
      case 'family':
        return TourCategory.family;
      case 'romantic':
        return TourCategory.romantic;
      case 'luxury':
        return TourCategory.luxury;
      case 'budget':
        return TourCategory.budget;
      default:
        throw ArgumentError('Unknown tour category: $value');
    }
  }

  /// Convert to JSON string (used by Tour model)
  String toJson() => name;

  /// Get all category names as strings
  static List<String> get categoryNames => 
      TourCategory.values.map((e) => e.displayName).toList();

  @override
  String toString() => displayName;
}