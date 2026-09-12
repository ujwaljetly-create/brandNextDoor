import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/order_model.dart';
import '../services/order_service.dart';
import '../widgets/order_card.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  String filter = 'New';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in to view received orders.')));
    }

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/seller-dashboard'),
          icon: const Icon(Icons.arrow_back, color: _navy),
        ),
        title: const Text('Orders', style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: OrderService().getSellerOrders(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _gold));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Could not load orders: ${snapshot.error}')));
          }

          final orders = snapshot.data ?? const <OrderModel>[];
          final filtered = orders.where((order) {
            return switch (filter) {
              'New' => order.status == 'pending',
              'Processing' => ['accepted', 'ready_for_pickup', 'out_for_delivery'].contains(order.status),
              'Completed' => order.status == 'delivered',
              'Cancelled' => ['cancelled', 'rejected'].contains(order.status),
              _ => true,
            };
          }).toList();

          int countFor(String label) => orders.where((order) {
                return switch (label) {
                  'New' => order.status == 'pending',
                  'Processing' => ['accepted', 'ready_for_pickup', 'out_for_delivery'].contains(order.status),
                  'Completed' => order.status == 'delivered',
                  'Cancelled' => ['cancelled', 'rejected'].contains(order.status),
                  _ => true,
                };
              }).length;

          return Column(
            children: [
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: ['New', 'Processing', 'Completed', 'Cancelled'].map((label) {
                    final selected = filter == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: selected,
                        selectedColor: _navy,
                        label: Text('$label (${countFor(label)})'),
                        labelStyle: TextStyle(color: selected ? Colors.white : _navy, fontWeight: FontWeight.w600, fontSize: 11.5),
                        onSelected: (_) => setState(() => filter = label),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text('No ${filter.toLowerCase()} orders.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 100),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          return OrderCard(
                            order: order,
                            onTap: () => context.push('/seller-order-details', extra: order),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _gold,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/create-listing'),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 1,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
        onDestinationSelected: (index) {
          if (index == 0) context.go('/seller-dashboard');
          if (index == 2) context.push('/messages');
          if (index == 3) context.push('/settings?role=seller');
        },
      ),
    );
  }
}
