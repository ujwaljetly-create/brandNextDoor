import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../models/order_model.dart';

/// All order mutations run on trusted Firebase Functions.
/// Read streams remain Firestore queries to preserve existing screens.
class OrderService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseFunctions functions = FirebaseFunctions.instance;

  Future<void> createOrder(OrderModel order) async {
    await functions.httpsCallable('createTrustedOrder').call({
      'orderId': order.orderId,
      'listingId': order.listingId,
      'quantity': order.quantity,
      'fulfillmentMethod': order.fulfillmentMethod,
    });
  }

  Stream<List<OrderModel>> getBuyerOrders(String buyerId) => firestore
      .collection('orders')
      .where('buyerId', isEqualTo: buyerId)
      .snapshots()
      .map((snapshot) {
        final orders = snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      });

  Stream<List<OrderModel>> getSellerOrders(String sellerId) => firestore
      .collection('orders')
      .where('sellerId', isEqualTo: sellerId)
      .snapshots()
      .map((snapshot) {
        final orders = snapshot.docs.map((doc) => OrderModel.fromMap(doc.data())).toList();
        orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return orders;
      });

  Future<void> _action(String orderId, String action, {String? reason}) async {
    await functions.httpsCallable('transitionTrustedOrder').call({
      'orderId': orderId,
      'action': action,
      if (reason != null) 'reason': reason,
    });
  }

  Future<void> acceptOrder(String orderId) => _action(orderId, 'accept');

  Future<void> rejectOrder({required String orderId, required String reason}) =>
      _action(orderId, 'reject', reason: reason);

  Future<void> cancelOrder(String orderId) => _action(orderId, 'cancel');

  Future<void> markReadyForPickup(String orderId) => _action(orderId, 'ready_for_pickup');

  Future<void> markOutForDelivery(String orderId) => _action(orderId, 'out_for_delivery');

  Future<void> markDelivered(String orderId) => _action(orderId, 'delivered');

  Future<void> updateStatus(String orderId, String status) {
    const actions = {
      'accepted': 'accept',
      'rejected': 'reject',
      'cancelled': 'cancel',
      'ready_for_pickup': 'ready_for_pickup',
      'out_for_delivery': 'out_for_delivery',
      'delivered': 'delivered',
    };
    final action = actions[status];
    if (action == null || action == 'reject') {
      throw ArgumentError.value(status, 'status', 'Use rejectOrder with a reason or a supported transition.');
    }
    return _action(orderId, action);
  }
}
