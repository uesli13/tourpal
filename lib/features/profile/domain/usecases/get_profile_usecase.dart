import '../repositories/profile_repository.dart';
import '../../../../models/user.dart';

class GetProfileUsecase {
  final ProfileRepository repository;

  GetProfileUsecase(this.repository);

  Future<User> call(String userId) async {
    return await repository.getProfile(userId);
  }
}