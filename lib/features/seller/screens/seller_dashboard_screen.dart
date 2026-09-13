import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../../models/order_model.dart';
import '../../brand/services/brand_service.dart';
import '../../listings/services/listing_service.dart';
import '../../orders/services/order_service.dart';
import '../../orders/widgets/order_card.dart';
import '../widgets/dashboard_stat_card.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  bool isLoading = true;
  bool brandExists = false;
  String brandName = '';
  String tagline = '';
  String logoUrl = '';

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
        brandName = (brand['brandName'] ?? '').toString();
        tagline = (brand['tagline'] ?? '').toString();
        logoUrl = (brand['logoUrl'] ?? '').toString();
      }
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = FirebaseAuth.instance.currentUser;
    final sellerName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : brandName.isNotEmpty
            ? brandName
            : 'Seller';

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadBrand,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                color: _navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'BRAND\nNEXT DOOR',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'serif',
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                              height: 0.95,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Seller', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.notifications_none, color: Colors.white),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => context.push('/settings?role=seller'),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFEAD8BA),
                            backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                            child: logoUrl.isEmpty ? const Icon(Icons.person_outline, color: _navy) : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Good morning,\n$sellerName 👋', style: const TextStyle(color: Colors.white, fontFamily: 'serif', fontSize: 27, height: 1.05, fontWeight: FontWeight.w600)),
                    if (tagline.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(tagline, style: const TextStyle(color: Color(0xFFD7DFE2), fontSize: 13)),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _tab('Overview', true),
                        _tab('Products', false, onTap: () => context.push('/my-listings')),
                        _tab('Insights', false, onTap: () => context.push('/seller-analytics')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE4DDD2))),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Last 30 days', style: TextStyle(color: _navy, fontSize: 12, fontWeight: FontWeight.w600)),
                          SizedBox(width: 8),
                          Icon(Icons.keyboard_arrow_down, size: 18, color: _navy),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (user == null)
                      const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Sign in to see seller activity.')))
                    else
                      StreamBuilder<List<OrderModel>>(
                        stream: OrderService().getSellerOrders(user.uid),
                        builder: (context, orderSnapshot) {
                          final orders = orderSnapshot.data ?? const <OrderModel>[];
                          final pending = orders.where((o) => o.status == 'pending').length;
                          final deliveredSales = orders.where((o) => o.status == 'delivered').fold<double>(0, (sum, o) => sum + o.amount);

                          return StreamBuilder<List<ListingModel>>(
                            stream: ListingService().getSellerListings(user.uid),
                            builder: (context, listingSnapshot) {
                              final listings = listingSnapshot.data ?? const <ListingModel>[];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1.18,
                                    children: [
                                      DashboardStatCard(title: 'Orders', value: orders.length.toString(), icon: Icons.shopping_bag_outlined, changeLabel: pending > 0 ? '$pending new' : null, onTap: () => context.push('/seller-orders')),
                                      DashboardStatCard(title: 'Total Sales', value: '\$${deliveredSales.toStringAsFixed(0)}', icon: Icons.attach_money, changeLabel: deliveredSales > 0 ? 'Completed orders' : null),
                                      DashboardStatCard(title: 'Products', value: listings.length.toString(), icon: Icons.inventory_2_outlined, onTap: () => context.push('/my-listings')),
                                      DashboardStatCard(title: 'Profile Visits', value: brandExists ? 'Live' : '—', icon: Icons.insights_outlined, changeLabel: brandExists ? 'Store active' : null, onTap: () => context.push('/seller-analytics')),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFFF4E5CD), Color(0xFFEED7AE)]),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Keep going!', style: TextStyle(color: _navy, fontWeight: FontWeight.w800)),
                                              SizedBox(height: 4),
                                              Text('Your products are reaching more people this week.', style: TextStyle(color: _navy, fontSize: 12, height: 1.35)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: List.generate(5, (i) => Container(margin: const EdgeInsets.only(left: 4), width: 5, height: 12.0 + (i * 7), decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(4)))),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  const Text('Quick Actions', style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: _quick(Icons.add_a_photo_outlined, 'Add Product', () => context.push('/create-listing'))),
                                      Expanded(child: _quick(Icons.inventory_2_outlined, 'Manage\nProducts', () => context.push('/my-listings'))),
                                      Expanded(child: _quick(Icons.receipt_long_outlined, 'View Orders', () => context.push('/seller-orders'))),
                                      Expanded(child: _quick(Icons.storefront_outlined, 'Preview Store', () => context.push('/seller-brand'))),
                                    ],
                                  ),
                                  const SizedBox(height: 26),
                                  Row(
                                    children: [
                                      const Expanded(child: Text('Recent Orders', style: TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w800))),
                                      TextButton(onPressed: () => context.push('/seller-orders'), child: const Text('View all')),
                                    ],
                                  ),
                                  if (orders.isEmpty)
                                    const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No customer orders yet.')))
                                  else
                                    ...orders.take(3).map((order) => OrderCard(order: order, onTap: () => context.push('/seller-order-details', extra: order))),
                                ],
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _gold,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/create-listing'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) context.push('/seller-orders');
          if (index == 2) context.push('/messages');
          if (index == 3) context.push('/settings?role=seller');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  Widget _tab(String label, bool active, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(label, style: TextStyle(color: active ? _navy : const Color(0xFF7A858B), fontSize: 12, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
              const SizedBox(height: 7),
              Container(height: 2, color: active ? _gold : Colors.transparent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quick(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE4DDD2))), child: Icon(icon, color: _navy)),
            const SizedBox(height: 7),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: _navy, fontSize: 10.5, fontWeight: FontWeight.w600, height: 1.15)),
          ],
        ),
      ),
    );
  }
}
