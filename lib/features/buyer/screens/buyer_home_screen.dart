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

  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController(viewportFraction: .94);
  Timer? _bannerTimer;

  String _searchText = '';
  String _cityName = 'Finding your location...';
  bool _locationLoading = true;
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentCity();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_bannerController.hasClients) return;
      final next = (_bannerIndex + 1) % 3;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _bannerIndex = next;
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentCity() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return _setCityFallback();
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return _setCityFallback();
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final places = await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = places.isNotEmpty ? places.first : null;
      final city = (place?.locality ?? '').trim();
      final fallback = (place?.subAdministrativeArea ?? '').trim();
      if (!mounted) return;
      setState(() {
        _cityName = city.isNotEmpty
            ? city
            : fallback.isNotEmpty
                ? fallback
                : 'Choose location';
        _locationLoading = false;
      });
    } catch (_) {
      _setCityFallback();
    }
  }

  void _setCityFallback() {
    if (!mounted) return;
    setState(() {
      _cityName = 'Choose location';
      _locationLoading = false;
    });
  }

  Future<void> _changeLocation() async {
    final controller = TextEditingController(
      text: _cityName == 'Choose location' || _locationLoading ? '' : _cityName,
    );
    final city = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change location'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'City name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogContext, '__current__'),
            icon: const Icon(Icons.my_location),
            label: const Text('Use current'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (city == null) return;
    if (city == '__current__') {
      setState(() {
        _cityName = 'Finding your location...';
        _locationLoading = true;
      });
      await _loadCurrentCity();
    } else {
      setState(() {
        _cityName = city;
        _locationLoading = false;
      });
    }
  }

  List<ListingModel> _filter(List<ListingModel> items) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.city.toLowerCase().contains(query);
    }).toList();
  }

  List<ListingModel> _recommendations(List<ListingModel> items, List<OrderModel> orders) {
    final interests = orders
        .where((o) => o.status == 'delivered')
        .map((o) => o.productCategory.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    final list = interests.isEmpty
        ? [...items]
        : items.where((e) => interests.contains(e.category.toLowerCase())).toList();
    list.sort((a, b) {
      final rating = b.rating.compareTo(a.rating);
      return rating != 0 ? rating : b.soldCount.compareTo(a.soldCount);
    });
    return list.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(buyerListingsProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: listingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load listings: $e'))),
          data: (items) {
            final filtered = _filter(items);
            final nearby = items.where((e) => _locationLoading || _cityName == 'Choose location' || e.city.toLowerCase() == _cityName.toLowerCase()).toList();
            final trending = [...nearby]..sort((a, b) => b.soldCount.compareTo(a.soldCount));
            final deals = nearby.where((e) => e.hasActiveDeal).toList();

            return Column(
              children: [
                _header(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _search(),
                      _categories(),
                      if (_searchText.isEmpty) ...[
                        _heroBanner(),
                        _section('Trending Near You', trending.take(6).toList()),
                        if (deals.isNotEmpty) _section('Hot Deals Near You', deals.take(6).toList()),
                        if (user == null)
                          _section('Based on Your Interest', items.take(6).toList())
                        else
                          StreamBuilder<List<OrderModel>>(
                            stream: OrderService().getBuyerOrders(user.uid),
                            builder: (_, snapshot) => _section(
                              'Based on Your Interest',
                              _recommendations(items, snapshot.data ?? const <OrderModel>[]),
                            ),
                          ),
                      ],
                      _discover(filtered),
                      const SizedBox(height: 90),
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
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'BRAND\nNEXT DOOR',
              style: TextStyle(color: Colors.white, fontFamily: 'serif', fontSize: 15, height: .95, letterSpacing: 3, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.white)),
          GestureDetector(
            onTap: () => context.push('/settings?role=buyer'),
            child: const CircleAvatar(
              radius: 19,
              backgroundColor: Color(0xFFE8D4B8),
              child: Icon(Icons.person_outline, color: navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _search() {
    return Container(
      color: navy,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discover something\nextraordinary nearby.',
            style: TextStyle(color: Colors.white, fontFamily: 'serif', fontSize: 25, height: 1.05),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchText = value),
            decoration: InputDecoration(
              hintText: 'Search brands & products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(onPressed: _changeLocation, icon: const Icon(Icons.tune)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 9),
          InkWell(
            onTap: _changeLocation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, color: gold, size: 17),
                const SizedBox(width: 5),
                Flexible(child: Text(_cityName, style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categories() {
    final data = <(String, IconData)>[
      ('Women', Icons.checkroom_outlined),
      ('Men', Icons.person_outline),
      ('Home', Icons.chair_outlined),
      ('Beauty', Icons.spa_outlined),
      ('More', Icons.more_horiz),
    ];
    return Container(
      color: navy,
      height: 68,
      padding: const EdgeInsets.fromLTRB(14, 5, 14, 10),
      child: Row(
        children: List.generate(
          data.length,
          (i) => Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/marketplace'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == 0 ? const Color(0xFFE8D4B8) : const Color(0xFF183543),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(data[i].$2, color: i == 0 ? navy : Colors.white, size: 20),
                    const SizedBox(height: 2),
                    Text(data[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: i == 0 ? navy : Colors.white, fontSize: 9.5)),
                  ],
                ),
              ),
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
        height: 205,
        child: PageView.builder(
          controller: _bannerController,
          itemCount: 3,
          onPageChanged: (index) => _bannerIndex = index,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(left: 16, right: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 330;
                return Container(
                  padding: EdgeInsets.all(compact ? 16 : 20),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              i == 0 ? 'LOCAL BRANDS\nBIGGER STORIES.' : 'SHOP SMALL.\nDISCOVER MORE.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: i.isEven ? Colors.white : navy,
                                fontFamily: 'serif',
                                fontSize: compact ? 18 : 20,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Exceptional style. Right next door.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: i.isEven ? Colors.white70 : navy,
                                fontSize: compact ? 11 : 12,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 32,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: gold,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: () => context.push('/marketplace'),
                                child: const Text('EXPLORE →', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.storefront_outlined, size: compact ? 48 : 62, color: i.isEven ? gold : navy),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<ListingModel> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: navy, fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700))),
              TextButton(onPressed: () => context.push('/marketplace'), child: const Text('See All')),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 215,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(width: 155, child: ProductCard(listing: items[i])),
            ),
          ),
        ],
      ),
    );
  }

  Widget _discover(List<ListingModel> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_searchText.isEmpty ? 'Discover Local Brands' : 'Search Results', style: const TextStyle(color: navy, fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No listings found.')))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: .72,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (_, i) => ProductCard(listing: items[i]),
            ),
        ],
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
        NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Saved'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
