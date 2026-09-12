import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../listings/services/listing_service.dart';
import '../widgets/product_card.dart';

class BuyerMarketplaceScreen extends StatefulWidget {
  const BuyerMarketplaceScreen({super.key});

  @override
  State<BuyerMarketplaceScreen> createState() => _BuyerMarketplaceScreenState();
}

class _BuyerMarketplaceScreenState extends State<BuyerMarketplaceScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  final searchController = TextEditingController();
  String searchText = '';
  String selectedCategory = 'All';

  final categories = const ['All', 'Fashion', 'Home Decor', 'Beauty', 'Food', 'Services', 'Electronics'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final category = GoRouterState.of(context).uri.queryParameters['category'];
    if (category != null && categories.contains(category)) {
      selectedCategory = category;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        title: const Text('Explore', style: TextStyle(color: _navy, fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: _navy)),
        ],
      ),
      body: StreamBuilder<List<ListingModel>>(
        stream: ListingService().getMarketplaceListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final source = snapshot.data ?? const <ListingModel>[];
          final listings = source.where((listing) {
            final q = searchText.trim().toLowerCase();
            final matchSearch = q.isEmpty ||
                listing.title.toLowerCase().contains(q) ||
                listing.description.toLowerCase().contains(q) ||
                listing.category.toLowerCase().contains(q);
            final matchCategory = selectedCategory == 'All' ||
                listing.category.toLowerCase().contains(selectedCategory.toLowerCase());
            return matchSearch && matchCategory;
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            children: [
              const Text('Find amazing brands around you.', style: TextStyle(color: Color(0xFF66747B))),
              const SizedBox(height: 14),
              TextField(
                controller: searchController,
                onChanged: (v) => setState(() => searchText = v),
                decoration: InputDecoration(
                  hintText: 'Search this area...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: const Icon(Icons.tune),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final active = categories[i] == selectedCategory;
                    return ChoiceChip(
                      selected: active,
                      label: Text(categories[i]),
                      onSelected: (_) => setState(() => selectedCategory = categories[i]),
                      selectedColor: _navy,
                      labelStyle: TextStyle(color: active ? Colors.white : _navy),
                      backgroundColor: Colors.white,
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              _heading('Just around the corner', 'Beautiful finds close to home.'),
              const SizedBox(height: 12),
              if (listings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: Text('No products match your search.')),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: listings.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: .72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (_, i) => ProductCard(listing: listings[i]),
                ),
              const SizedBox(height: 24),
              _heading('New brands near you', 'Recently joined independent businesses.'),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: source.take(6).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(width: 160, child: ProductCard(listing: source[i])),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _gold,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/account-type'),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/buyer-home');
          if (index == 2) context.push('/buyer-orders');
          if (index == 3) context.push('/settings?role=buyer');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _heading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: _navy, fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: Color(0xFF7A858B), fontSize: 12)),
      ],
    );
  }
}
