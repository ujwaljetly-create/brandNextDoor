import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isFollowing(String brandId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || brandId.isEmpty) return false;
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(brandId)
        .get();
    return doc.exists;
  }

  Stream<bool> watchFollowing(String brandId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || brandId.isEmpty) return Stream.value(false);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('following')
        .doc(brandId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> follow({
    required String brandId,
    required String sellerId,
    required String brandName,
    required String brandLogoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Please sign in to follow sellers.');

    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();

    batch.set(
      _firestore.collection('users').doc(user.uid).collection('following').doc(brandId),
      {
        'brandId': brandId,
        'sellerId': sellerId,
        'brandName': brandName,
        'brandLogoUrl': brandLogoUrl,
        'followedAt': now,
      },
      SetOptions(merge: true),
    );

    batch.set(
      _firestore.collection('brands').doc(brandId).collection('followers').doc(user.uid),
      {
        'userId': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'followedAt': now,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> unfollow(String brandId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || brandId.isEmpty) return;

    final batch = _firestore.batch();
    batch.delete(
      _firestore.collection('users').doc(user.uid).collection('following').doc(brandId),
    );
    batch.delete(
      _firestore.collection('brands').doc(brandId).collection('followers').doc(user.uid),
    );
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchFollowers(String brandId) {
    if (brandId.isEmpty) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _firestore
        .collection('brands')
        .doc(brandId)
        .collection('followers')
        .orderBy('followedAt', descending: true)
        .snapshots();
  }
}
