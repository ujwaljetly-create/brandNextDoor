import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String listingId;

  final String productTitle;

  final double amount;

  final int quantity;

  final String status;

  final Timestamp createdAt;

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.listingId,
    required this.productTitle,
    required this.amount,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return OrderModel(
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      listingId: map['listingId'] ?? '',
      productTitle:
          map['productTitle'] ?? '',
      amount:
          (map['amount'] ?? 0)
              .toDouble(),
      quantity:
          map['quantity'] ?? 1,
      status:
          map['status'] ?? 'pending',
      createdAt:
          map['createdAt'] ??
              Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'listingId': listingId,
      'productTitle': productTitle,
      'amount': amount,
      'quantity': quantity,
      'status': status,
      'createdAt': createdAt,
    };
  }
}