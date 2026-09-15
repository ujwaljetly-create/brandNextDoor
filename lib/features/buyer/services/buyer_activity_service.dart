import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/listing_model.dart';

class BuyerActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> recordListingView(ListingModel listing) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('browsingHistory')
        .add({
      'listingId': listing.listingId,
      'category': listing.category,
      'brandId': listing.brandId,
      'viewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Set<String>> getRecentViewedCategories({int limit = 50}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return <String>{};

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('browsingHistory')
        .orderBy('viewedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['category'] ?? '').toString().trim().toLowerCase())
        .where((category) => category.isNotEmpty)
        .toSet();
  }
}
