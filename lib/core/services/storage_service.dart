import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/logger.dart';
import '../exceptions/app_exceptions.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Upload a file to Firebase Storage
  Future<String> uploadFile(File file, String path) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.storage('Uploading file', path);

    try {
      if (!file.existsSync()) {
        throw const StorageException('File not found');
      }

      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      stopwatch.stop();
      AppLogger.performance('File Upload', stopwatch.elapsed);
      AppLogger.storage('File uploaded successfully', downloadUrl);

      return downloadUrl;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase Storage error uploading file', e);
      throw StorageException('Failed to upload file: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error uploading file', e);
      throw const StorageException('Failed to upload file');
    }
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      AppLogger.storage('File deleted successfully', url);
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase Storage error deleting file', e);
      throw StorageException('Failed to delete file: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error deleting file', e);
      throw const StorageException('Failed to delete file');
    }
  }

  /// Get download URL for a file
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase Storage error getting download URL', e);
      throw StorageException('Failed to get download URL: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error getting download URL', e);
      throw const StorageException('Failed to get download URL');
    }
  }
}