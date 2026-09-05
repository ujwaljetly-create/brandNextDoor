import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String brandId;
  final String listingId;
  final String productTitle;
  final double unitPrice;
  final double amount;
  final int quantity;
  final String fulfillmentMethod;
  final String status;
  final Timestamp createdAt;

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.brandId,
    required this.listingId,
    required this.productTitle,
    required this.unitPrice,
    required this.amount,
    required this.quantity,
    required this.fulfillmentMethod,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final amount = (map['amount'] ?? 0).toDouble();
    final quantity = (map['quantity'] ?? 1) as int;

    return OrderModel(
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      brandId: map['brandId'] ?? '',
      listingId: map['listingId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      unitPrice: (map['unitPrice'] ??
              (quantity > 0 ? amount / quantity : amount))
          .toDouble(),
      amount: amount,
      quantity: quantity,
      fulfillmentMethod: map['fulfillmentMethod'] ?? 'pickup',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'brandId': brandId,
      'listingId': listingId,
      'productTitle': productTitle,
      'unitPrice': unitPrice,
      'amount': amount,
      'quantity': quantity,
      'fulfillmentMethod': fulfillmentMethod,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
