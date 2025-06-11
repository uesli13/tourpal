import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../models/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting the current authenticated user
class GetCurrentUserUsecase {
  final AuthRepository _authRepository;

  GetCurrentUserUsecase(this._authRepository);

  /// Gets the current authenticated user
  /// Returns the user if authenticated, throws exception if not
  Future<User> call() async {
    try {
      AppLogger.info('GetCurrentUserUsecase: Checking current user status');
      
      final user = await _authRepository.getCurrentUser();
      
      if (user == null) {
        AppLogger.info('GetCurrentUserUsecase: No current user found');
        throw const AuthenticationException('No authenticated user found');
      }
      
      AppLogger.info('GetCurrentUserUsecase: Current user found', user.id);
      return user;
    } catch (e) {
      AppLogger.error('GetCurrentUserUsecase: Failed to get current user', e);
      if (e is AppException) {
        rethrow;
      }
      throw AuthenticationException('Failed to get current user: ${e.toString()}');
    }
  }
}