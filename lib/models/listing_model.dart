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
  });

  factory ListingModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ListingModel(
      listingId: map['listingId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      brandId: map['brandId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      images: List<String>.from(
        map['images'] ?? [],
      ),
      deliveryAvailable:
          map['deliveryAvailable'] ?? false,
      pickupAvailable:
          map['pickupAvailable'] ?? false,
      category: map['category'] ?? '',
      status: map['status'] ?? 'active',
      createdAt:
          map['createdAt'] ?? Timestamp.now(),
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
      'createdAt': createdAt,
    };
  }
}