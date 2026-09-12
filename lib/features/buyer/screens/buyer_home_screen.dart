import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../../models/order_model.dart';
import '../../orders/services/order_service.dart';
import '../providers/buyer_home_provider.dart';
import '../widgets/product_card.dart';

class BuyerHomeScreen extends ConsumerStatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  ConsumerState<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends ConsumerState<BuyerHomeScreen> {
  static const navy = Color(0xFF0C2430);
  static const gold = Color(0xFFC99245);
  static const cream = Color(0xFFF8F3EA);

  final _searchController = TextEditingController();
  final _bannerController = PageController(viewportFraction: .94);
  Timer? _bannerTimer;
  String _search = '';
  String _city = 'Nearby';
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCity();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_bannerController.hasClients) return;
      _bannerIndex = (_bannerIndex + 1) % 3;
      _bannerController.animateToPage(
        _bannerIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCity() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (!mounted || places.isEmpty) return;
      final name = (places.first.locality ?? '').trim();
      if (name.isNotEmpty) setState(() => _city = name);
    } catch (_) {}
  }

  List<ListingModel> _filter(List<ListingModel> items) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();
  }

  List<ListingModel> _recommended(List<ListingModel> items, List<OrderModel> orders) {
    final categories = orders
        .where((o) => o.status == 'delivered')
        .map((o) => o.productCategory.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final result = categories.isEmpty
        ? [...items]
        : items.where((e) => categories.contains(e.category.toLowerCase())).toList();
    result.sort((a, b) {
      final sold = b.soldCount.compareTo(a.soldCount);
      return sold != 0 ? sold : b.rating.compareTo(a.rating);
    });
    return result.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncListings = ref.watch(buyerListingsProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: asyncListings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load marketplace: $e')),
          data: (items) {
            final visible = _filter(items);
            final hotDeals = items.where((e) => e.hasActiveDeal).take(8).toList();
            final trending = [...items]
              ..sort((a, b) {
                final sold = b.soldCount.compareTo(a.soldCount);
                return sold != 0 ? sold : b.rating.compareTo(a.rating);
              });

            return Column(
              children: [
                _header(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _searchBar(),
                      if (_search.isEmpty) ...[
                        _categories(),
                        _heroBanner(),
                        _sectionTitle('Trending Near You', onTap: () => context.push('/marketplace')),
                        _horizontalProducts(trending.take(8).toList()),
                        if (hotDeals.isNotEmpty) ...[
                          _sectionTitle('Hot Deals in $_city', onTap: () => context.push('/marketplace')),
                          _horizontalProducts(hotDeals),
                        ],
                        _sectionTitle('Based on Your Interest'),
                        if (user == null)
                          _horizontalProducts(items.take(8).toList())
                        else
                          StreamBuilder<List<OrderModel>>(
                            stream: OrderService().getBuyerOrders(user.uid),
                            builder: (context, snapshot) =>
                                _horizontalProducts(_recommended(items, snapshot.data ?? const [])),
                          ),
                        _sectionTitle('Discover Local Brands'),
                      ] else
                        _sectionTitle('Search Results'),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                        child: visible.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(30),
                                child: Center(child: Text('No products found.')),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: visible.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: .72,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemBuilder: (_, i) => ProductCard(listing: visible[i]),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: gold,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/account-type'),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header() {
    return Container(
      color: navy,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'BRAND\nNEXT DOOR',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'serif',
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                height: .95,
                fontSize: 15,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Discover nearby', style: TextStyle(color: Colors.white70, fontSize: 11)),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: gold, size: 17),
                  const SizedBox(width: 4),
                  Text(_city, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => context.push('/settings?role=buyer'),
            icon: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Search brands & products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.tune),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _categories() {
    const data = [
      ('Women', Icons.checkroom_outlined),
      ('Men', Icons.person_outline),
      ('Home', Icons.home_outlined),
      ('Beauty', Icons.spa_outlined),
      ('Food', Icons.restaurant_outlined),
    ];
    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => InkWell(
          onTap: () => context.push('/marketplace?category=${Uri.encodeComponent(data[i].$1)}'),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 68,
            decoration: BoxDecoration(
              color: i == 0 ? const Color(0xFFEADCC7) : navy,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data[i].$2, color: i == 0 ? navy : Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(data[i].$1, style: TextStyle(color: i == 0 ? navy : Colors.white, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        height: 165,
        child: PageView.builder(
          controller: _bannerController,
          itemCount: 3,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(left: 16, right: 6),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: i.isEven ? navy : const Color(0xFFE8D4B8),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          i == 0 ? 'LOCAL BRANDS\nBIGGER STORIES.' : 'SHOP SMALL.\nDISCOVER MORE.',
                          style: TextStyle(
                            color: i.isEven ? Colors.white : navy,
                            fontFamily: 'serif',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Exceptional style. Right next door.', style: TextStyle(color: i.isEven ? Colors.white70 : navy)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 34,
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: gold),
                            onPressed: () => context.push('/marketplace'),
                            child: const Text('EXPLORE →'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.storefront_outlined, size: 72, color: i.isEven ? gold : navy),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: navy, fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700))),
          if (onTap != null) TextButton(onPressed: onTap, child: const Text('See All')),
        ],
      ),
    );
  }

  Widget _horizontalProducts(List<ListingModel> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text('More local finds are coming soon.'),
      );
    }
    return SizedBox(
      height: 240,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => SizedBox(width: 170, child: ProductCard(listing: items[i])),
      ),
    );
  }

  Widget _bottomNav() {
    return NavigationBar(
      backgroundColor: Colors.white,
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) context.push('/marketplace');
        if (index == 2) context.push('/buyer-orders');
        if (index == 3) context.push('/settings?role=buyer');
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
        NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
