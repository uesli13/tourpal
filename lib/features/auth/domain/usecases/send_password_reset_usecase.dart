import '../repositories/auth_repository.dart';

class SendPasswordResetUsecase {
  final AuthRepository repository;

  SendPasswordResetUsecase(this.repository);

  Future<void> call(String email) async {
    return await repository.sendPasswordResetEmail(email);
  }
}