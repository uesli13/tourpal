import '../repositories/auth_repository.dart';
import '../../../../models/user.dart' as app_user;

class SignInWithGoogleUsecase {
  final AuthRepository repository;

  SignInWithGoogleUsecase(this.repository);

  Future<app_user.User> call() async {
    return await repository.signInWithGoogle();
  }
}