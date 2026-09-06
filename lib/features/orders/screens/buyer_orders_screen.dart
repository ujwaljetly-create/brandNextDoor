import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/order_model.dart';
import '../../brand/services/brand_service.dart';
import '../services/order_service.dart';
import '../widgets/order_card.dart';

class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

  Future<void> _cancelOrder(
    BuildContext context,
    OrderModel order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text(
          'You can cancel only while the order is still awaiting seller acceptance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await OrderService().cancelOrder(order.orderId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final card = (Map<String, dynamic>? brand) {
      final brandName = (brand?['brandName'] ?? order.sellerName).toString();
      final logoUrl = (brand?['logoUrl'] ?? order.sellerLogoUrl).toString();

      return OrderCard(
        order: order,
        showSellerInfo: true,
        sellerNameOverride: brandName,
        sellerLogoUrlOverride: logoUrl,
        onSellerTap: order.sellerId.isEmpty
            ? null
            : () {
                context.push(
                  '/seller-storefront',
                  extra: {
                    'sellerId': order.sellerId,
                    'brandId': order.brandId,
                  },
                );
              },
        action: order.canBuyerCancel
            ? SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelOrder(context, order),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Order'),
                ),
              )
            : null,
      );
    };

    if (order.brandId.isEmpty) {
      return card(null);
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: BrandService().getBrand(order.brandId),
      builder: (context, snapshot) {
        return card(snapshot.data);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view your orders.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().getBuyerOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load orders: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final orders = snapshot.data ?? const <OrderModel>[];

          if (orders.isEmpty) {
            return const Center(
              child: Text('You have not placed any orders yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(context, orders[index]);
            },
          );
        },
      ),
    );
  }
}
