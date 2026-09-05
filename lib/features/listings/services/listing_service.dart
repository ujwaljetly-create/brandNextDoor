import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;
Future<void> deleteListing(
  String listingId,
) async {
  await firestore
      .collection('listings')
      .doc(listingId)
      .delete();
}

Future<void> updateListing(
  ListingModel listing,
) async {
  await firestore
      .collection('listings')
      .doc(listing.listingId)
      .update(
        listing.toMap(),
      );
}
  Future<void> createListing(
    ListingModel listing,
  ) async {
    await firestore
        .collection('listings')
        .doc(listing.listingId)
        .set(
          listing.toMap(),
        );
  }

  Stream<List<ListingModel>> getSellerListings(
    String sellerId,
  ) {
    return firestore
        .collection('listings')
.where(
  'sellerId',
  isEqualTo: sellerId,
)
.orderBy(
  'createdAt',
  descending: true,
)
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs
            .map(
              (doc) => ListingModel.fromMap(
                doc.data(),
              ),
            )
            .toList();
      },
    );
  }
  Stream<List<ListingModel>> getActiveListings() {
  return firestore
      .collection('listings')
      .where(
        'status',
        isEqualTo: 'active',
      )
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => ListingModel.fromMap(
                doc.data(),
              ),
            )
            .toList(),
      );
}
Stream<List<ListingModel>>
    getMarketplaceListings() {
  return firestore
      .collection('listings')
      .where(
        'status',
        isEqualTo: 'active',
      )
      .orderBy(
        'createdAt',
        descending: true,
      )
      .snapshots()
      .map(
        (snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    ListingModel.fromMap(
                  doc.data(),
                ),
              )
              .toList();
        },
      );
}
}