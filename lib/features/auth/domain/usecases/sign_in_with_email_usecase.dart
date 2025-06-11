import '../repositories/auth_repository.dart';
import '../../../../models/user.dart' as app_user;

class SignInWithEmailUsecase {
  final AuthRepository repository;

  SignInWithEmailUsecase(this.repository);

  Future<app_user.User> call({
    required String email,
    required String password,
  }) async {
    return await repository.signInWithEmailAndPassword(email, password);
  }
}