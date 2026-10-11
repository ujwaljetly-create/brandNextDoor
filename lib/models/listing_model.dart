import 'package:cloud_firestore/cloud_firestore.dart';

class ListingModel {
  final String listingId;
  final String sellerId;
  final String brandId;

  final String title;
  final String description;
  final double price;
  final List<String> images;

  final bool deliveryAvailable;
  final bool pickupAvailable;
  final String category;
  final String status;
  final String city;

  final bool isHotDeal;
  final double dealPrice;
  final Timestamp? dealStartAt;
  final Timestamp? dealEndAt;

  final int soldCount;
  final double rating;
  final int reviewCount;

  final Timestamp createdAt;

  ListingModel({
    required this.listingId,
    required this.sellerId,
    required this.brandId,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    required this.deliveryAvailable,
    required this.pickupAvailable,
    required this.category,
    required this.status,
    required this.createdAt,
    this.city = '',
    this.isHotDeal = false,
    this.dealPrice = 0,
    this.dealStartAt,
    this.dealEndAt,
    this.soldCount = 0,
    this.rating = 0,
    this.reviewCount = 0,
  });

  factory ListingModel.fromMap(Map<String, dynamic> map) {
    final soldValue = map['soldCount'] ?? 0;
    final reviewsValue = map['reviewCount'] ?? 0;

    return ListingModel(
      listingId: map['listingId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      brandId: map['brandId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      images: List<String>.from(map['images'] ?? []),
      deliveryAvailable: map['deliveryAvailable'] ?? false,
      pickupAvailable: map['pickupAvailable'] ?? false,
      category: map['category'] ?? '',
      status: map['status'] ?? 'active',
      city: (map['city'] ?? '').toString(),
      isHotDeal: map['isHotDeal'] ?? false,
      dealPrice: (map['dealPrice'] ?? 0).toDouble(),
      dealStartAt: map['dealStartAt'] as Timestamp?,
      dealEndAt: map['dealEndAt'] as Timestamp?,
      soldCount: soldValue is int
          ? soldValue
          : int.tryParse(soldValue.toString()) ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: reviewsValue is int
          ? reviewsValue
          : int.tryParse(reviewsValue.toString()) ?? 0,
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'sellerId': sellerId,
      'brandId': brandId,
      'title': title,
      'description': description,
      'price': price,
      'images': images,
      'deliveryAvailable': deliveryAvailable,
      'pickupAvailable': pickupAvailable,
      'category': category,
      'status': status,
      'city': city,
      'isHotDeal': isHotDeal,
      'dealPrice': dealPrice,
      'dealStartAt': dealStartAt,
      'dealEndAt': dealEndAt,
      'soldCount': soldCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt,
    };
  }

  bool get hasActiveDeal {
    if (!isHotDeal || dealPrice <= 0 || dealPrice >= price) return false;

    final now = DateTime.now();
    final start = dealStartAt?.toDate();
    final end = dealEndAt?.toDate();

    if (start != null && now.isBefore(start)) return false;
    if (end != null && now.isAfter(end)) return false;

    return true;
  }

  double get currentPrice => hasActiveDeal ? dealPrice : price;

  int get discountPercent {
    if (!hasActiveDeal || price <= 0) return 0;
    return (((price - dealPrice) / price) * 100).round();
  }
}
