import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> deleteListing(String listingId) async {
    await firestore.collection('listings').doc(listingId).delete();
  }

  Future<void> updateListing(ListingModel listing) async {
    await firestore
        .collection('listings')
        .doc(listing.listingId)
        .update(listing.toMap());
  }

  Future<void> createListing(ListingModel listing) async {
    await firestore
        .collection('listings')
        .doc(listing.listingId)
        .set(listing.toMap());
  }

  Stream<List<ListingModel>> getSellerListings(String sellerId) {
    return firestore
        .collection('listings')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs
          .map((doc) => ListingModel.fromMap(doc.data()))
          .toList();
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return listings;
    });
  }

  Stream<List<ListingModel>> getActiveSellerListings(String sellerId) {
    return firestore
        .collection('listings')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs
          .map((doc) => ListingModel.fromMap(doc.data()))
          .where((listing) => listing.status == 'active')
          .toList();
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return listings;
    });
  }

  Stream<List<ListingModel>> getActiveListings() {
    return firestore
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs
          .map((doc) => ListingModel.fromMap(doc.data()))
          .toList();
      listings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return listings;
    });
  }

  Stream<List<ListingModel>> getMarketplaceListings() {
    return getActiveListings();
  }
}
