import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/order_model.dart';
import '../../brand/services/brand_service.dart';
import '../../reviews/services/review_service.dart';
import '../services/order_service.dart';
import '../widgets/order_card.dart';

class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  Future<void> _cancelOrder(
    BuildContext context,
    OrderModel order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        surfaceTintColor: _cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel order?'),
        content: const Text(
          'You can cancel only while the order is still awaiting seller acceptance.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _navy),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white),
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

  Widget? _buildAction(BuildContext context, OrderModel order) {
    if (order.canBuyerCancel) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _cancelOrder(context, order),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel Order'),
        ),
      );
    }

    if (order.status != 'delivered') return null;

    return StreamBuilder<bool>(
      stream: ReviewService().hasReviewedOrder(order.orderId),
      builder: (context, snapshot) {
        final reviewed = snapshot.data ?? false;

        return SizedBox(
          width: double.infinity,
          child: reviewed
              ? OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Reviewed'),
                )
              : ElevatedButton.icon(
                  onPressed: () {
                    context.push(
                      '/review-order',
                      extra: order,
                    );
                  },
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Review Item & Seller'),
                ),
        );
      },
    );
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
        action: _buildAction(context, order),
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
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        surfaceTintColor: _cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: _navy),
        title: const Text('My Orders', style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().getBuyerOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _gold));
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
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shopping_bag_outlined, color: _gold, size: 52),
                  SizedBox(height: 14),
                  Text('No orders yet', style: TextStyle(color: _navy, fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('Your purchases from local brands will appear here.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF68747A))),
                ]),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
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
