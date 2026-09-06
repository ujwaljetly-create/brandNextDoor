import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/order_model.dart';
import '../../brand/services/brand_service.dart';
import '../../brand/widgets/brand_status_card.dart';
import '../../orders/services/order_service.dart';
import '../../orders/widgets/order_card.dart';
import '../widgets/dashboard_stat_card.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() =>
      _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  bool isLoading = true;
  bool brandExists = false;
  String brandName = '';
  String tagline = '';
  String logoUrl = '';
  int completion = 0;

  @override
  void initState() {
    super.initState();
    loadBrand();
  }

  Future<void> loadBrand() async {
    try {
      final brand = await BrandService().getSellerBrand();

      if (brand != null) {
        brandExists = true;
        brandName = brand['brandName'] ?? '';
        tagline = brand['tagline'] ?? '';
        logoUrl = brand['logoUrl'] ?? '';
        completion = 0;

        if (brandName.isNotEmpty) completion += 25;
        if (tagline.isNotEmpty) completion += 25;
        if ((brand['description'] ?? '').toString().isNotEmpty) {
          completion += 25;
        }
        if (logoUrl.isNotEmpty) completion += 25;
      }
    } catch (e) {
      debugPrint('Load Brand Error: $e');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final seller = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              context.push('/settings?role=seller');
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadBrand,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome Back 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your brand and grow your business',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              BrandStatusCard(
                brandExists: brandExists,
                brandName: brandName,
                tagline: tagline,
                logoUrl: logoUrl,
                completion: completion,
                onPressed: () {
                  if (!brandExists) {
                    context.push('/seller-onboarding');
                  } else {
                    context.push('/seller-brand');
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/create-listing');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push('/my-listings');
                      },
                      icon: const Icon(Icons.inventory),
                      label: const Text('My Listings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (seller == null)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Sign in to see order activity.'),
                  ),
                )
              else
                StreamBuilder<List<OrderModel>>(
                  stream: OrderService().getSellerOrders(seller.uid),
                  builder: (context, snapshot) {
                    final orders = snapshot.data ?? const <OrderModel>[];
                    final deliveredSales = orders
                        .where((order) => order.status == 'delivered')
                        .fold<double>(0, (sum, order) => sum + order.amount);
                    final pending = orders
                        .where((order) => order.status == 'pending')
                        .length;

                    final statCards = <Widget>[
                      DashboardStatCard(
                        title: pending > 0
                            ? 'Orders ($pending new)'
                            : 'Orders',
                        value: orders.length.toString(),
                        icon: Icons.shopping_bag,
                        onTap: () {
                          context.push('/seller-orders');
                        },
                      ),
                      DashboardStatCard(
                        title: 'Sales',
                        value: '\$${deliveredSales.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                      ),
                      const DashboardStatCard(
                        title: 'Listings',
                        value: '—',
                        icon: Icons.inventory,
                      ),
                      const DashboardStatCard(
                        title: 'Messages',
                        value: '—',
                        icon: Icons.chat_bubble,
                      ),
                    ];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: statCards.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 145,
                          ),
                          itemBuilder: (context, index) => statCards[index],
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Recent Orders',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                context.push('/seller-orders');
                              },
                              child: const Text('View all'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            orders.isEmpty)
                          const Center(child: CircularProgressIndicator())
                        else if (orders.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                brandExists
                                    ? 'No customer orders yet.'
                                    : 'Create your brand to start receiving orders.',
                              ),
                            ),
                          )
                        else
                          ...orders.take(3).map(
                                (order) => OrderCard(
                                  order: order,
                                  onTap: () {
                                    context.push(
                                      '/seller-order-details',
                                      extra: order,
                                    );
                                  },
                                ),
                              ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
