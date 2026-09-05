import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/order_model.dart';

class OrderService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> createOrder(
    OrderModel order,
  ) async {
    await firestore
        .collection('orders')
        .doc(order.orderId)
        .set(order.toMap());
  }

  Stream<List<OrderModel>> getBuyerOrders(
    String buyerId,
  ) {
    return firestore
        .collection('orders')
        .where(
          'buyerId',
          isEqualTo: buyerId,
        )
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map(
            (doc) => OrderModel.fromMap(doc.data()),
          )
          .toList();

      orders.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return orders;
    });
  }

  Stream<List<OrderModel>> getSellerOrders(
    String sellerId,
  ) {
    return firestore
        .collection('orders')
        .where(
          'sellerId',
          isEqualTo: sellerId,
        )
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map(
            (doc) => OrderModel.fromMap(doc.data()),
          )
          .toList();

      orders.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      return orders;
    });
  }

  Future<void> updateStatus(
    String orderId,
    String status,
  ) async {
    await firestore.collection('orders').doc(orderId).update({
      'status': status,
    });
  }
}
