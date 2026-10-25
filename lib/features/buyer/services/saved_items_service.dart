import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/listing_model.dart';

class SavedItemsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _savedRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('savedItems');
  }

  Stream<Set<String>> watchSavedIds(String uid) {
    return _savedRef(uid).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => doc.id).toSet(),
        );
  }

  Stream<List<ListingModel>> watchSavedItems(String uid) {
    return _savedRef(uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ListingModel.fromMap(doc.data()))
            .toList());
  }

  Future<bool> isSaved({
    required String uid,
    required String listingId,
  }) async {
    final doc = await _savedRef(uid).doc(listingId).get();
    return doc.exists;
  }

  Future<void> save({
    required String uid,
    required ListingModel listing,
  }) async {
    await _savedRef(uid).doc(listing.listingId).set({
      ...listing.toMap(),
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove({
    required String uid,
    required String listingId,
  }) async {
    await _savedRef(uid).doc(listingId).delete();
  }

  Future<bool> toggle({
    required String uid,
    required ListingModel listing,
  }) async {
    final saved = await isSaved(uid: uid, listingId: listing.listingId);
    if (saved) {
      await remove(uid: uid, listingId: listing.listingId);
      return false;
    }
    await save(uid: uid, listing: listing);
    return true;
  }
}
