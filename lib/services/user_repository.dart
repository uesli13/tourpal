import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'user';

  Future<void> createUser(User user) {
    return _db
      .collection(_collection)
      .doc(user.id)
      .set(user.toJson());
  }

  Future<User?> fetchUser(String uid) async {
    final snap = await _db.collection(_collection).doc(uid).get();
    if (!snap.exists) return null;
    return User.fromJson(snap.data()!);
  }

}
