import 'base_exception.dart';

/// Exception thrown when an operation related to tours fails.
class TourException extends TourPalException {
  const TourException(super.message, [super.code]);
}

/// Exception thrown when tour creation validation fails.
class TourValidationException extends TourException {
  const TourValidationException(super.message, [super.code]);

  factory TourValidationException.emptyTitle() {
    return const TourValidationException(
      'Tour title cannot be empty',
      'invalid-title',
    );
  }

  factory TourValidationException.tooLongTitle() {
    return const TourValidationException(
      'Tour title must be 100 characters or less',
      'title-too-long',
    );
  }

  factory TourValidationException.emptyDescription() {
    return const TourValidationException(
      'Tour description cannot be empty',
      'invalid-description',
    );
  }

  factory TourValidationException.noStops() {
    return const TourValidationException(
      'Tour must have at least one stop',
      'no-stops',
    );
  }

  factory TourValidationException.invalidDuration() {
    return const TourValidationException(
      'Tour duration must be greater than 0',
      'invalid-duration',
    );
  }

  factory TourValidationException.invalidLocation() {
    return const TourValidationException(
      'Tour must have a valid starting location',
      'invalid-location',
    );
  }
}

/// Exception thrown when a tour operation fails due to service/firebase errors.
class TourServiceException extends TourException {
  const TourServiceException(super.message, [super.code]);

  factory TourServiceException.failedToCreate() {
    return const TourServiceException(
      'Failed to create tour',
      'create-failed',
    );
  }

  factory TourServiceException.failedToUpdate() {
    return const TourServiceException(
      'Failed to update tour',
      'update-failed',
    );
  }

  factory TourServiceException.failedToDelete() {
    return const TourServiceException(
      'Failed to delete tour',
      'delete-failed',
    );
  }

  factory TourServiceException.failedToLoad() {
    return const TourServiceException(
      'Failed to load tour',
      'load-failed',
    );
  }

  factory TourServiceException.tourNotFound() {
    return const TourServiceException(
      'Tour not found',
      'not-found',
    );
  }

  factory TourServiceException.notAuthorized() {
    return const TourServiceException(
      'You are not authorized to perform this operation',
      'not-authorized',
    );
  }
}

/// Exception thrown when a tour operation fails due to networking issues.
class TourNetworkException extends TourException {
  const TourNetworkException(super.message, [super.code]);

  factory TourNetworkException.connection() {
    return const TourNetworkException(
      'Network connection error',
      'network-error',
    );
  }

  factory TourNetworkException.timeout() {
    return const TourNetworkException(
      'Request timed out',
      'timeout',
    );
  }
}