import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../../models/order_model.dart';
import '../../listings/services/listing_service.dart';
import '../../orders/services/order_service.dart';

class SellerAnalyticsScreen extends StatelessWidget {
  const SellerAnalyticsScreen({super.key});

  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view analytics.')),
      );
    }

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/seller-dashboard'),
          icon: const Icon(Icons.arrow_back, color: _navy),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: _navy,
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().getSellerOrders(user.uid),
        builder: (context, orderSnapshot) {
          final orders = orderSnapshot.data ?? const <OrderModel>[];
          final delivered =
              orders.where((order) => order.status == 'delivered').toList();
          final totalSales = delivered.fold<double>(
            0,
            (sum, order) => sum + order.amount,
          );
          final totalUnits = delivered.fold<int>(
            0,
            (sum, order) => sum + order.quantity,
          );
          final averageOrderValue =
              delivered.isEmpty ? 0.0 : totalSales / delivered.length;

          return StreamBuilder<List<ListingModel>>(
            stream: ListingService().getSellerListings(user.uid),
            builder: (context, listingSnapshot) {
              final listings = listingSnapshot.data ?? const <ListingModel>[];
              final topProducts = [...listings]
                ..sort((a, b) => b.soldCount.compareTo(a.soldCount));

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Last 30 days',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE4DDD2)),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Overview',
                              style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: _navy,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.25,
                    children: [
                      _MetricCard(
                        title: 'Total Sales',
                        value: '\$${totalSales.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                      ),
                      _MetricCard(
                        title: 'Orders',
                        value: delivered.length.toString(),
                        icon: Icons.receipt_long_outlined,
                      ),
                      _MetricCard(
                        title: 'Units Sold',
                        value: totalUnits.toString(),
                        icon: Icons.shopping_bag_outlined,
                      ),
                      _MetricCard(
                        title: 'Avg. Order',
                        value: '\$${averageOrderValue.toStringAsFixed(0)}',
                        icon: Icons.trending_up,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE6DED2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sales performance',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 150,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(8, (index) {
                              final factor = delivered.isEmpty
                                  ? 0.15 + (index * 0.05)
                                  : 0.25 + ((index % 5) * 0.12);
                              return Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Container(
                                    height: 120 * factor,
                                    decoration: BoxDecoration(
                                      color: _gold.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Top Products',
                    style: TextStyle(
                      color: _navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (topProducts.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('No product data available yet.'),
                      ),
                    )
                  else
                    ...topProducts.take(5).map(
                          (listing) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border:
                                  Border.all(color: const Color(0xFFE6DED2)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 58,
                                    height: 58,
                                    child: listing.images.isNotEmpty
                                        ? Image.network(
                                            listing.images.first,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                              Icons.image_outlined,
                                            ),
                                          )
                                        : const Icon(Icons.image_outlined),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _navy,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${listing.soldCount} sold',
                                        style: const TextStyle(
                                          color: Color(0xFF6D787E),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${listing.currentPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: _navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/seller-dashboard');
          if (index == 1) context.push('/seller-orders');
          if (index == 2) context.push('/messages');
          if (index == 3) context.push('/settings?role=seller');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SellerAnalyticsScreen._gold, size: 22),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SellerAnalyticsScreen._navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6D787E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
