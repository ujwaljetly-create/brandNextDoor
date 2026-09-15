import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String orderId;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String brandId;
  final String listingId;
  final String productTitle;
  final double itemRating;
  final double sellerRating;
  final String comment;
  final Timestamp createdAt;

  ReviewModel({
    required this.reviewId,
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.brandId,
    required this.listingId,
    required this.productTitle,
    required this.itemRating,
    required this.sellerRating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      reviewId: map['reviewId'] ?? '',
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      sellerId: map['sellerId'] ?? '',
      brandId: map['brandId'] ?? '',
      listingId: map['listingId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      itemRating: (map['itemRating'] ?? 0).toDouble(),
      sellerRating: (map['sellerRating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'orderId': orderId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'brandId': brandId,
      'listingId': listingId,
      'productTitle': productTitle,
      'itemRating': itemRating,
      'sellerRating': sellerRating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}
