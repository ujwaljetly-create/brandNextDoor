import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../../models/order_model.dart';
import '../../../widgets/notification_bell.dart';
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
  static const _navy = Color(0xFF0C2430), _gold = Color(0xFFC99245), _cream = Color(0xFFF8F3EA);
  bool isLoading = true, brandExists = false;
  String brandName = '', tagline = '', logoUrl = '';

  @override
  void initState() { super.initState(); loadBrand(); }
  Future<void> loadBrand() async {
    try {
      final brand = await BrandService().getSellerBrand();
      if (brand != null) { brandExists = true; brandName = (brand['brandName'] ?? '').toString(); tagline = (brand['tagline'] ?? '').toString(); logoUrl = (brand['logoUrl'] ?? '').toString(); }
    } catch (_) {}
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final user = FirebaseAuth.instance.currentUser;
    final sellerName = user?.displayName?.trim().isNotEmpty == true ? user!.displayName!.trim() : 'Seller';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(child: RefreshIndicator(onRefresh: loadBrand, child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
        Container(color: _navy, padding: const EdgeInsets.fromLTRB(20, 18, 20, 22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('BRAND\nNEXT DOOR', style: TextStyle(color: Colors.white, fontFamily: 'serif', fontWeight: FontWeight.w700, letterSpacing: 3, height: .95, fontSize: 15))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(20)), child: const Text('Seller', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
            const SizedBox(width: 4),
            NotificationBell(onPressed: () => context.push('/notifications')),
            GestureDetector(onTap: () => context.push('/settings?role=seller'), child: CircleAvatar(radius: 20, backgroundColor: const Color(0xFFEAD8BA), backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null, child: logoUrl.isEmpty ? const Icon(Icons.person_outline, color: _navy) : null)),
          ]),
          const SizedBox(height: 20),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: logoUrl.isNotEmpty
                  ? Image.network(logoUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.storefront, color: _navy))
                  : const Icon(Icons.storefront, color: _navy, size: 34),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(greeting, style: const TextStyle(color: Color(0xFFD7DFE2), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(brandName.isNotEmpty ? brandName : sellerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontFamily: 'serif', fontSize: 25, fontWeight: FontWeight.w700)),
              if (brandName.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(sellerName, style: const TextStyle(color: Color(0xFFD7DFE2), fontSize: 12)),
              ],
            ])),
          ]),
          if (tagline.isNotEmpty) ...[const SizedBox(height: 10), Text(tagline, style: const TextStyle(color: Color(0xFFD7DFE2), fontSize: 13))],
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 100), child: user == null ? const Text('Sign in to see seller activity.') : StreamBuilder<List<OrderModel>>(
          stream: OrderService().getSellerOrders(user.uid), builder: (context, orderSnap) {
            final orders = orderSnap.data ?? const <OrderModel>[];
            final pending = orders.where((o) => o.status == 'pending').length;
            final sales = orders.where((o) => o.status == 'delivered').fold<double>(0, (s, o) => s + o.amount);
            return StreamBuilder<List<ListingModel>>(stream: ListingService().getSellerListings(user.uid), builder: (context, listingSnap) {
              final listings = listingSnap.data ?? const <ListingModel>[];
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [_tab('Overview', true), _tab('Products', false, () => context.push('/my-listings')), _tab('Insights', false, () => context.push('/seller-analytics'))]),
                const SizedBox(height: 18),
                GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.18, children: [
                  DashboardStatCard(title: 'Orders', value: orders.length.toString(), icon: Icons.shopping_bag_outlined, changeLabel: pending > 0 ? '$pending new' : null, onTap: () => context.push('/seller-orders')),
                  DashboardStatCard(title: 'Total Sales', value: '\$${sales.toStringAsFixed(2)}', icon: Icons.attach_money),
                  DashboardStatCard(title: 'Products', value: listings.length.toString(), icon: Icons.inventory_2_outlined, onTap: () => context.push('/my-listings')),
                  DashboardStatCard(title: 'Store', value: brandExists ? 'Live' : 'Setup', icon: Icons.storefront_outlined, onTap: () => context.push(brandExists ? '/seller-brand' : '/seller-onboarding')),
                ]),
                const SizedBox(height: 24),
                const Text('Quick Actions', style: TextStyle(color: _navy, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
                Row(children: [Expanded(child: _quick(Icons.add_a_photo_outlined, 'Add Product', () => context.push('/create-listing'))), Expanded(child: _quick(Icons.inventory_2_outlined, 'Products', () => context.push('/my-listings'))), Expanded(child: _quick(Icons.receipt_long_outlined, 'Orders', () => context.push('/seller-orders'))), Expanded(child: _quick(Icons.people_outline, 'Followers', () => context.push('/seller-followers')))]),
                const SizedBox(height: 24),
                Row(children: [const Expanded(child: Text('Recent Orders', style: TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.w800))), TextButton(onPressed: () => context.push('/seller-orders'), child: const Text('View all'))]),
                if (orders.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('No customer orders yet.'))) else ...orders.take(3).map((o) => OrderCard(order: o, onTap: () => context.push('/seller-order-details', extra: o))),
              ]);
            });
          },
        )),
      ]))),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(backgroundColor: _gold, foregroundColor: Colors.white, onPressed: () => context.push('/create-listing'), child: const Icon(Icons.add)),
      bottomNavigationBar: NavigationBar(backgroundColor: Colors.white, selectedIndex: 0, onDestinationSelected: (i) { if (i == 1) context.push('/seller-orders'); if (i == 2) context.push('/messages?role=seller'); if (i == 3) context.push('/settings?role=seller'); }, destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'), NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'), NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More')]),
    );
  }

  Widget _tab(String text, bool active, [VoidCallback? tap]) => Expanded(child: InkWell(onTap: tap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Column(children: [Text(text, style: TextStyle(color: active ? _navy : const Color(0xFF7A858B), fontWeight: active ? FontWeight.w800 : FontWeight.w500)), const SizedBox(height: 7), Container(height: 2, color: active ? _gold : Colors.transparent)]))));
  Widget _quick(IconData icon, String label, VoidCallback tap) => InkWell(onTap: tap, child: Padding(padding: const EdgeInsets.all(5), child: Column(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE4DDD2))), child: Icon(icon, color: _navy)), const SizedBox(height: 7), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: _navy, fontSize: 10.5, fontWeight: FontWeight.w600))])));
}
