import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../listings/services/listing_service.dart';
import '../services/buyer_activity_service.dart';
import '../widgets/product_card.dart';

class BuyerMarketplaceScreen extends StatefulWidget {
  const BuyerMarketplaceScreen({super.key});

  @override
  State<BuyerMarketplaceScreen> createState() => _BuyerMarketplaceScreenState();
}

class _BuyerMarketplaceScreenState extends State<BuyerMarketplaceScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _cream = Color(0xFFF8F3EA);

  final searchController = TextEditingController();
  String searchText = '';
  String selectedCategory = 'All';
  String mode = '';
  Set<String> viewedCategories = <String>{};

  final categories = const [
    'All',
    'Fashion',
    'Food',
    'Home Decor',
    'Beauty',
    'Services',
    'Electronics',
    'Art & Handmade',
    'Jewelry',
    'Kids',
    'Health & Wellness',
    'Gifts',
    'Pets',
  ];

  @override
  void initState() {
    super.initState();
    _loadBrowsingHistory();
  }

  Future<void> _loadBrowsingHistory() async {
    try {
      final categories = await BuyerActivityService().getRecentViewedCategories();
      if (mounted) setState(() => viewedCategories = categories);
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final category = uri.queryParameters['category'];
    mode = uri.queryParameters['mode'] ?? '';
    if (category != null && categories.contains(category)) {
      selectedCategory = category;
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool _matchesCategory(ListingModel listing) {
    if (selectedCategory == 'All') return true;
    final actual = listing.category.trim().toLowerCase();
    final selected = selectedCategory.toLowerCase();
    if (selected == 'fashion') {
      return actual.contains('fashion') || actual.contains('women') || actual.contains('men');
    }
    if (selected == 'home decor') {
      return actual.contains('home') || actual.contains('decor');
    }
    return actual == selected || actual.contains(selected);
  }

  Future<void> _showMoreCategories() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('All Categories', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _navy)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final active = selectedCategory == category;
                  return ChoiceChip(
                    selected: active,
                    label: Text(category),
                    selectedColor: _navy,
                    labelStyle: TextStyle(color: active ? Colors.white : _navy),
                    onSelected: (_) => Navigator.pop(context, category),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (value != null && mounted) setState(() => selectedCategory = value);
  }

  void _sortInterest(List<ListingModel> listings) {
    int score(ListingModel item) {
      var result = item.soldCount * 3 + item.rating.round() * 5;
      if (viewedCategories.contains(item.category.trim().toLowerCase())) {
        result += 120;
      }
      return result;
    }

    listings.sort((a, b) => score(b).compareTo(score(a)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        title: Text(
          mode == 'interest' ? 'Based on Your Interest' : 'Explore',
          style: const TextStyle(color: _navy, fontFamily: 'serif', fontSize: 28, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<ListingModel>>(
        stream: ListingService().getMarketplaceListings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final source = snapshot.data ?? const <ListingModel>[];
          var listings = source.where((listing) {
            final q = searchText.trim().toLowerCase();
            final matchSearch = q.isEmpty ||
                listing.title.toLowerCase().contains(q) ||
                listing.description.toLowerCase().contains(q) ||
                listing.category.toLowerCase().contains(q);
            return matchSearch && _matchesCategory(listing);
          }).toList();

          if (mode == 'interest') {
            _sortInterest(listings);
            listings = listings.take(25).toList();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            children: [
              Text(
                mode == 'interest'
                    ? 'Top 25 picks shaped by your browsing and shopping activity.'
                    : 'Find amazing brands around you.',
                style: const TextStyle(color: Color(0xFF66747B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: searchController,
                onChanged: (v) => setState(() => searchText = v),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
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
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    if (i == 6) {
                      return ActionChip(
                        avatar: const Icon(Icons.more_horiz, size: 18),
                        label: const Text('More'),
                        onPressed: _showMoreCategories,
                      );
                    }
                    final category = categories[i];
                    final active = category == selectedCategory;
                    return ChoiceChip(
                      selected: active,
                      label: Text(category),
                      onSelected: (_) => setState(() => selectedCategory = category),
                      selectedColor: _navy,
                      labelStyle: TextStyle(color: active ? Colors.white : _navy),
                      backgroundColor: Colors.white,
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              Text(
                mode == 'interest' ? 'Recommended for you' : 'Just around the corner',
                style: const TextStyle(color: _navy, fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (listings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: Text('No products match this filter.')),
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
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/buyer-home');
          if (index == 1) return;
          if (index == 2) context.push('/buyer-orders');
          if (index == 3) context.push('/settings?role=buyer');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
