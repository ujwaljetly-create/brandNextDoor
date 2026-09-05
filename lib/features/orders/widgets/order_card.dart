import 'package:flutter/material.dart';

import '../../../models/order_model.dart';

class OrderCard
    extends StatelessWidget {
  final OrderModel order;

  const OrderCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(
      BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: ListTile(
        title:
            Text(order.productTitle),
        subtitle: Text(
          'Qty: ${order.quantity}\nStatus: ${order.status}',
        ),
        trailing: Text(
          '\$${order.amount}',
        ),
      ),
    );
  }
}