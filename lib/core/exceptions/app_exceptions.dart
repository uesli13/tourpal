abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.code});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

// Feature-specific exceptions following TOURPAL rules
class ProfileException extends AppException {
  const ProfileException(super.message, {super.code});
}

class ProfileValidationException extends ProfileException {
  const ProfileValidationException(super.message);
}

class ProfileServiceException extends ProfileException {
  const ProfileServiceException(super.message);
}

class GuideException extends AppException {
  const GuideException(super.message, {super.code});
}

class GuideValidationException extends GuideException {
  const GuideValidationException(super.message);
}

class GuideServiceException extends GuideException {
  const GuideServiceException(super.message);
}

class TourException extends AppException {
  const TourException(super.message, {super.code});
}

class TourValidationException extends TourException {
  const TourValidationException(super.message);
}

class TourServiceException extends TourException {
  const TourServiceException(super.message);
}

class BookingException extends AppException {
  const BookingException(super.message, {super.code});
}

class BookingValidationException extends BookingException {
  const BookingValidationException(super.message);
}

class BookingServiceException extends BookingException {
  const BookingServiceException(super.message);
}

class ReviewException extends AppException {
  const ReviewException(super.message, {super.code});
}

class ReviewValidationException extends ReviewException {
  const ReviewValidationException(super.message);
}

class ReviewServiceException extends ReviewException {
  const ReviewServiceException(super.message);
}

class MessageException extends AppException {
  const MessageException(super.message, {super.code});
}

class MessageValidationException extends MessageException {
  const MessageValidationException(super.message);
}

class MessageServiceException extends MessageException {
  const MessageServiceException(super.message);
}

class JournalException extends AppException {
  const JournalException(super.message, {super.code});
}

class JournalValidationException extends JournalException {
  const JournalValidationException(super.message);
}

class JournalServiceException extends JournalException {
  const JournalServiceException(super.message);
}

class DashboardException extends AppException {
  const DashboardException(super.message, {super.code});
}

class DashboardValidationException extends DashboardException {
  const DashboardValidationException(super.message);
}

class DashboardServiceException extends DashboardException {
  const DashboardServiceException(super.message);
}