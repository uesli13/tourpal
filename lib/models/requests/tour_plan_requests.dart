import 'package:equatable/equatable.dart';

/// Request model for creating a new tour plan
class TourPlanCreateRequest extends Equatable {
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double? budget;
  final List<String> categories;
  final bool isPublic;
  final String? coverImageUrl;

  const TourPlanCreateRequest({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.budget,
    this.categories = const [],
    this.isPublic = false,
    this.coverImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budget': budget,
      'categories': categories,
      'isPublic': isPublic,
      'coverImageUrl': coverImageUrl,
    };
  }

  @override
  List<Object?> get props => [
    title,
    description,
    startDate,
    endDate,
    budget,
    categories,
    isPublic,
    coverImageUrl,
  ];
}

/// Request model for updating an existing tour plan
class TourPlanUpdateRequest extends Equatable {
  final String? title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? budget;
  final List<String>? categories;
  final bool? isPublic;
  final String? coverImageUrl;

  const TourPlanUpdateRequest({
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.budget,
    this.categories,
    this.isPublic,
    this.coverImageUrl,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (startDate != null) map['startDate'] = startDate!.toIso8601String();
    if (endDate != null) map['endDate'] = endDate!.toIso8601String();
    if (budget != null) map['budget'] = budget;
    if (categories != null) map['categories'] = categories;
    if (isPublic != null) map['isPublic'] = isPublic;
    if (coverImageUrl != null) map['coverImageUrl'] = coverImageUrl;
    
    return map;
  }

  @override
  List<Object?> get props => [
    title,
    description,
    startDate,
    endDate,
    budget,
    categories,
    isPublic,
    coverImageUrl,
  ];
}

/// Request model for searching tour plans with filters
class TourPlanSearchFilters extends Equatable {
  final String? searchTerm;
  final List<String>? categories;
  final double? minBudget;
  final double? maxBudget;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isPublic;
  final String? userId; // Filter by specific user
  final int? limit;
  final String? lastDocumentId; // For pagination

  const TourPlanSearchFilters({
    this.searchTerm,
    this.categories,
    this.minBudget,
    this.maxBudget,
    this.startDate,
    this.endDate,
    this.isPublic,
    this.userId,
    this.limit,
    this.lastDocumentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'searchTerm': searchTerm,
      'categories': categories,
      'minBudget': minBudget,
      'maxBudget': maxBudget,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isPublic': isPublic,
      'userId': userId,
      'limit': limit,
      'lastDocumentId': lastDocumentId,
    };
  }

  @override
  List<Object?> get props => [
    searchTerm,
    categories,
    minBudget,
    maxBudget,
    startDate,
    endDate,
    isPublic,
    userId,
    limit,
    lastDocumentId,
  ];
}