enum TourSortOption {  name('Name', 'Sort tours alphabetically by name'),
    price('Price', 'Sort tours by price from low to high'),
    duration('Duration', 'Sort tours by duration'),
    rating('Rating', 'Sort tours by average rating'),
    popularity('Popularity', 'Sort tours by booking popularity'),
    distance('Distance', 'Sort tours by distance from your location'),
    newest('Newest', 'Show newest tours first'),
    featured('Featured', 'Show featured tours first');

  const TourSortOption(this.displayName, this.description);
    final String displayName;
    final String description;
}