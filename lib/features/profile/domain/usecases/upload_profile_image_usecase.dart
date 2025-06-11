import 'dart:io';
import '../repositories/profile_repository.dart';

class UploadProfileImageUsecase {
  final ProfileRepository repository;

  UploadProfileImageUsecase(this.repository);

  Future<String> call(String userId, File imageFile) async {
    return await repository.uploadProfileImage(userId, imageFile);
  }
}