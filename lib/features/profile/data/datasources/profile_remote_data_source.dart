import 'dart:io';
import '../../../../models/user.dart';

abstract class ProfileRemoteDataSource {
  Future<User> getProfile(String userId);
  
  Future<void> updateProfile(User user);
  
  Future<String> uploadProfileImage(String userId, File imageFile);
  
  Future<void> deleteProfileImage(String userId);
  
  Stream<User?> watchProfile(String userId);
}