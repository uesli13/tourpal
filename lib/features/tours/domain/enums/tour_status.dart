enum TourStatus {
  draft('draft', 'Draft', '📝'),
  published('published', 'Published', '✅'),
  suspended('suspended', 'Suspended', '⏸️');

  const TourStatus(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static TourStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'draft':
        return TourStatus.draft;
      case 'published':
        return TourStatus.published;
      case 'suspended':
        return TourStatus.suspended;
      default:
        return TourStatus.draft;
    }
  }

  bool get isDraft => this == TourStatus.draft;
  bool get isPublished => this == TourStatus.published;
  bool get isSuspended => this == TourStatus.suspended;

  String get description {
    switch (this) {
      case TourStatus.draft:
        return 'Tour is saved as draft and not visible to public';
      case TourStatus.published:
        return 'Tour is live and visible to all users';
      case TourStatus.suspended:
        return 'Tour is temporarily suspended';
    }
  }

  @override
  String toString() => value;
}