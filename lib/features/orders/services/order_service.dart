import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/order_model.dart';

class OrderService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> createOrder(OrderModel order) async {
    await firestore
        .collection('orders')
        .doc(order.orderId)
        .set(order.toMap());
  }

  Stream<List<OrderModel>> getBuyerOrders(String buyerId) {
    return firestore
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();

      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Stream<List<OrderModel>> getSellerOrders(String sellerId) {
    return firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();

      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> acceptOrder(String orderId) async {
    await _transition(
      orderId: orderId,
      fromStatus: 'pending',
      toStatus: 'accepted',
      extra: {
        'acceptedAt': Timestamp.now(),
      },
    );
  }

  Future<void> rejectOrder({
    required String orderId,
    required String reason,
  }) async {
    await _transition(
      orderId: orderId,
      fromStatus: 'pending',
      toStatus: 'rejected',
      extra: {
        'rejectionReason': reason.trim(),
        'completedAt': Timestamp.now(),
      },
    );
  }

  Future<void> cancelOrder(String orderId) async {
    await _transition(
      orderId: orderId,
      fromStatus: 'pending',
      toStatus: 'cancelled',
      extra: {
        'completedAt': Timestamp.now(),
      },
    );
  }

  Future<void> markReadyForPickup(String orderId) async {
    await _transition(
      orderId: orderId,
      fromStatus: 'accepted',
      toStatus: 'ready_for_pickup',
    );
  }

  Future<void> markOutForDelivery(String orderId) async {
    await _transition(
      orderId: orderId,
      fromStatus: 'accepted',
      toStatus: 'out_for_delivery',
    );
  }

  Future<void> markDelivered(String orderId) async {
    final orderRef = firestore.collection('orders').doc(orderId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) {
        throw Exception('Order no longer exists.');
      }

      final data = snapshot.data()!;
      final current = data['status'] ?? '';
      if (current != 'ready_for_pickup' &&
          current != 'out_for_delivery') {
        throw Exception('Order is not ready to be completed.');
      }

      final listingId = (data['listingId'] ?? '').toString();
      final quantityValue = data['quantity'] ?? 1;
      final quantity = quantityValue is int
          ? quantityValue
          : int.tryParse(quantityValue.toString()) ?? 1;

      transaction.update(orderRef, {
        'status': 'delivered',
        'updatedAt': Timestamp.now(),
        'completedAt': Timestamp.now(),
      });

      if (listingId.isNotEmpty) {
        final listingRef = firestore.collection('listings').doc(listingId);
        final listingSnapshot = await transaction.get(listingRef);

        if (listingSnapshot.exists) {
          final soldValue = listingSnapshot.data()?['soldCount'] ?? 0;
          final soldCount = soldValue is int
              ? soldValue
              : int.tryParse(soldValue.toString()) ?? 0;

          transaction.update(listingRef, {
            'soldCount': soldCount + quantity,
          });
        }
      }
    });
  }

  Future<void> updateStatus(String orderId, String status) async {
    await firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> _transition({
    required String orderId,
    required String fromStatus,
    required String toStatus,
    Map<String, dynamic>? extra,
  }) async {
    final ref = firestore.collection('orders').doc(orderId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        throw Exception('Order no longer exists.');
      }

      final current = snapshot.data()?['status'] ?? '';
      if (current != fromStatus) {
        throw Exception('Order status has already changed.');
      }

      transaction.update(ref, {
        'status': toStatus,
        'updatedAt': Timestamp.now(),
        ...?extra,
      });
    });
  }
}
