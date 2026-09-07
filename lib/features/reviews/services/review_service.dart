import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/review_model.dart';

class ReviewService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Stream<bool> hasReviewedOrder(String orderId) {
    return firestore
        .collection('reviews')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<ReviewModel>> getListingReviews(String listingId) {
    return firestore
        .collection('reviews')
        .where('listingId', isEqualTo: listingId)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }

  Stream<List<ReviewModel>> getSellerReviews(String sellerId) {
    return firestore
        .collection('reviews')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data()))
          .toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }

  Future<void> submitReview(ReviewModel review) async {
    final reviewRef = firestore.collection('reviews').doc(review.orderId);
    final orderRef = firestore.collection('orders').doc(review.orderId);
    final listingRef = firestore.collection('listings').doc(review.listingId);
    final brandRef = firestore.collection('brands').doc(review.brandId);

    await firestore.runTransaction((transaction) async {
      final existingReview = await transaction.get(reviewRef);
      if (existingReview.exists) {
        throw Exception('You have already reviewed this order.');
      }

      final orderDoc = await transaction.get(orderRef);
      if (!orderDoc.exists) {
        throw Exception('Order not found.');
      }

      final orderData = orderDoc.data()!;
      if (orderData['status'] != 'delivered') {
        throw Exception('Reviews can be submitted only after delivery.');
      }
      if ((orderData['buyerId'] ?? '').toString() != review.buyerId) {
        throw Exception('You cannot review this order.');
      }

      final listingDoc = await transaction.get(listingRef);
      if (!listingDoc.exists) {
        throw Exception('Listing not found.');
      }

      final listingData = listingDoc.data()!;
      final oldItemCount = (listingData['reviewCount'] ?? 0) as num;
      final oldItemRating = (listingData['rating'] ?? 0) as num;
      final newItemCount = oldItemCount.toInt() + 1;
      final newItemRating =
          ((oldItemRating.toDouble() * oldItemCount.toDouble()) +
                  review.itemRating) /
              newItemCount;

      transaction.update(listingRef, {
        'rating': newItemRating,
        'reviewCount': newItemCount,
      });

      if (review.brandId.isNotEmpty) {
        final brandDoc = await transaction.get(brandRef);
        if (brandDoc.exists) {
          final brandData = brandDoc.data()!;
          final oldSellerCount = (brandData['totalReviews'] ?? 0) as num;
          final oldSellerRating = (brandData['rating'] ?? 0) as num;
          final newSellerCount = oldSellerCount.toInt() + 1;
          final newSellerRating =
              ((oldSellerRating.toDouble() * oldSellerCount.toDouble()) +
                      review.sellerRating) /
                  newSellerCount;

          transaction.update(brandRef, {
            'rating': newSellerRating,
            'totalReviews': newSellerCount,
          });
        }
      }

      transaction.set(reviewRef, review.toMap());
      transaction.update(orderRef, {
        'reviewed': true,
        'reviewedAt': Timestamp.now(),
      });
    });
  }
}
