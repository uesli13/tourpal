import '../repositories/auth_repository.dart';
import '../../../../models/user.dart' as app_user;

class SignUpWithEmailUsecase {
  final AuthRepository repository;

  SignUpWithEmailUsecase(this.repository);

  Future<app_user.User> call({
    required String email,
    required String password,
    required String name,
  }) async {
    return await repository.signUpWithEmailAndPassword(email, password, name);
  }
}