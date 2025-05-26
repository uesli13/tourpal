// Custom exceptions for tour plan validation
class TourPlanValidationException implements Exception {
  final String message;
  final String? field;
  
  const TourPlanValidationException(this.message, {this.field});
  
  @override
  String toString() => 'TourPlanValidationException: $message${field != null ? ' (field: $field)' : ''}';
}

class TourPlanNotFoundException implements Exception {
  final String tourPlanId;
  
  const TourPlanNotFoundException(this.tourPlanId);
  
  @override
  String toString() => 'TourPlanNotFoundException: Tour plan with ID $tourPlanId not found';
}

class TourPlanPermissionException implements Exception {
  final String message;
  
  const TourPlanPermissionException(this.message);
  
  @override
  String toString() => 'TourPlanPermissionException: $message';
}