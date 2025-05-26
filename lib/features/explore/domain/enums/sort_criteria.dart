/// Sort criteria enum for tour exploration
/// Follows TOURPAL development rules for enums
enum SortCriteria {
  name('Name'),
  price('Price'),
  duration('Duration'),
  rating('Rating'),
  popularity('Popularity'),
  distance('Distance'),
  newest('Newest'),
  featured('Featured');

  const SortCriteria(this.displayName);

  final String displayName;

  /// Icon for each sort criteria
  String get icon {
    switch (this) {
      case SortCriteria.name:
        return '🔤';
      case SortCriteria.price:
        return '💰';
      case SortCriteria.duration:
        return '⏱️';
      case SortCriteria.rating:
        return '⭐';
      case SortCriteria.popularity:
        return '🔥';
      case SortCriteria.distance:
        return '📍';
      case SortCriteria.newest:
        return '🆕';
      case SortCriteria.featured:
        return '✨';
    }
  }
}