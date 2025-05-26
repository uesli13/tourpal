import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/errors/error_handler.dart';

abstract class BaseRepository {
  final FirebaseFirestore _firestore;
  
  BaseRepository(this._firestore);
  
  /// Get Firestore instance
  FirebaseFirestore get firestore => _firestore;
  
  /// Handle Firestore exceptions and convert to app exceptions
  T handleFirestoreError<T>(Function() operation) {
    try {
      return operation();
    } on FirebaseException catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Database error: ${e.message}', e.code);
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Unexpected error: $e');
    }
  }
  
  /// Handle async Firestore operations
  Future<T> handleAsyncFirestoreError<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Database error: ${e.message}', e.code);
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Unexpected error: $e');
    }
  }
}