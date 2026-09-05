import 'package:flutter/material.dart';

import '../services/order_service.dart';
import '../widgets/order_card.dart';

class BuyerOrdersScreen
    extends StatelessWidget {
  const BuyerOrdersScreen({
    super.key,
  });

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('My Orders'),
      ),
      body: StreamBuilder(
        stream: OrderService()
            .getBuyerOrders(
          'demoBuyerId',
        ),
        builder:
            (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final orders =
              snapshot.data!;

          return ListView.builder(
            itemCount:
                orders.length,
            itemBuilder:
                (context, index) {
              return OrderCard(
                order:
                    orders[index],
              );
            },
          );
        },
      ),
    );
  }
}