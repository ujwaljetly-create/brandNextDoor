import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../services/listing_service.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  final searchController = TextEditingController();
  String search = '';
  String filter = 'All';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in to view products.')));
    }

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _navy),
          onPressed: () => context.canPop() ? context.pop() : context.go('/seller-dashboard'),
        ),
        title: const Text('My Products', style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<ListingModel>>(
        stream: ListingService().getSellerListings(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _gold));
          }
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));

          final all = snapshot.data ?? const <ListingModel>[];
          final items = all.where((listing) {
            final q = search.toLowerCase();
            final matchesSearch = q.isEmpty || listing.title.toLowerCase().contains(q) || listing.category.toLowerCase().contains(q);
            final matchesFilter = switch (filter) {
              'Active' => listing.status == 'active',
              'Hot Deals' => listing.hasActiveDeal,
              _ => true,
            };
            return matchesSearch && matchesFilter;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() => search = value),
                  decoration: InputDecoration(
                    hintText: 'Search your products...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  children: ['All', 'Active', 'Hot Deals'].map((label) {
                    final selected = filter == label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: selected,
                        label: Text(label),
                        onSelected: (_) => setState(() => filter = label),
                        selectedColor: _navy,
                        labelStyle: TextStyle(color: selected ? Colors.white : _navy, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final listing = items[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE6DED2)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 74,
                                      height: 74,
                                      child: listing.images.isNotEmpty
                                          ? Image.network(listing.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                                          : _placeholder(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text('\$${listing.currentPrice.toStringAsFixed(2)} • ${listing.soldCount} sold', style: const TextStyle(color: _navy, fontSize: 12.5)),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            _badge(listing.status == 'active' ? 'Active' : listing.status, const Color(0xFF2A8F6A)),
                                            if (listing.hasActiveDeal) _badge('${listing.discountPercent}% OFF', _gold),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    iconColor: _navy,
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit Product')),
                                      PopupMenuItem(value: 'delete', child: Text('Delete Product')),
                                    ],
                                    onSelected: (value) => _handleAction(context, value, listing),
                                  ),
                                ],
                              ),
                            ),
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
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
        onDestinationSelected: (index) {
          if (index == 0) context.go('/seller-dashboard');
          if (index == 1) context.push('/seller-orders');
          if (index == 2) context.push('/messages');
          if (index == 3) context.push('/settings?role=seller');
        },
      ),
    );
  }

  Widget _placeholder() => Container(color: const Color(0xFFF1E8DB), child: const Icon(Icons.image_outlined, color: _navy));

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
      );

  Future<void> _handleAction(BuildContext context, String value, ListingModel listing) async {
    if (value == 'edit') {
      await context.push('/edit-listing', extra: listing);
      return;
    }
    if (value != 'delete') return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await ListingService().deleteListing(listing.listingId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
      }
    }
  }
}
