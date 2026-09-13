import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String sellerLogoUrl;
  final String brandId;
  final String listingId;
  final String productTitle;
  final String productImageUrl;
  final String productCategory;
  final double unitPrice;
  final double amount;
  final int quantity;
  final String fulfillmentMethod;
  final String status;
  final String rejectionReason;
  final Timestamp createdAt;
  final Timestamp? acceptedAt;
  final Timestamp? updatedAt;
  final Timestamp? completedAt;

  OrderModel({
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.sellerLogoUrl,
    required this.brandId,
    required this.listingId,
    required this.productTitle,
    required this.productImageUrl,
    this.productCategory = '',
    required this.unitPrice,
    required this.amount,
    required this.quantity,
    required this.fulfillmentMethod,
    required this.status,
    required this.rejectionReason,
    required this.createdAt,
    this.acceptedAt,
    this.updatedAt,
    this.completedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final amount = (map['amount'] ?? 0).toDouble();
    final quantityValue = map['quantity'] ?? 1;
    final quantity = quantityValue is int
        ? quantityValue
        : int.tryParse(quantityValue.toString()) ?? 1;

    return OrderModel(
      orderId: map['orderId'] ?? '',
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerLogoUrl: map['sellerLogoUrl'] ?? '',
      brandId: map['brandId'] ?? '',
      listingId: map['listingId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      productCategory: map['productCategory'] ?? '',
      unitPrice: (map['unitPrice'] ??
              (quantity > 0 ? amount / quantity : amount))
          .toDouble(),
      amount: amount,
      quantity: quantity,
      fulfillmentMethod: map['fulfillmentMethod'] ?? 'pickup',
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejectionReason'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      acceptedAt: map['acceptedAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
      completedAt: map['completedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerLogoUrl': sellerLogoUrl,
      'brandId': brandId,
      'listingId': listingId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'productCategory': productCategory,
      'unitPrice': unitPrice,
      'amount': amount,
      'quantity': quantity,
      'fulfillmentMethod': fulfillmentMethod,
      'status': status,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
      'acceptedAt': acceptedAt,
      'updatedAt': updatedAt,
      'completedAt': completedAt,
    };
  }

  bool get canBuyerCancel => status == 'pending';
  bool get canSellerAccept => status == 'pending';
  bool get canSellerReject => status == 'pending';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Awaiting seller';
      case 'accepted':
        return 'Accepted';
      case 'ready_for_pickup':
        return 'Ready for pickup';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ');
    }
  }
}
