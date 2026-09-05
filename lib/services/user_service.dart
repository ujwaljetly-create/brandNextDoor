import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<UserModel?> getUser(
    String uid,
  ) async {
    final doc =
        await firestore
            .collection('users')
            .doc(uid)
            .get();

    if (!doc.exists) {
      return null;
    }

    return UserModel.fromMap(
      doc.data()!,
    );
  }

  Stream<UserModel?> getUserStream(
    String uid,
  ) {
    return firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map(
      (doc) {
        if (!doc.exists) {
          return null;
        }

        return UserModel.fromMap(
          doc.data()!,
        );
      },
    );
  }
}