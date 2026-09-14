import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../../models/order_model.dart';
import '../../brand/services/brand_service.dart';
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
  final _dealController = PageController(viewportFraction: .91);
  Timer? _dealTimer;

  String _searchText = '';
  String _cityName = 'Finding your location...';
  bool _locationLoading = true;
  int _dealIndex = 0;
  int _dealCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentCity();
    _dealTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_dealController.hasClients || _dealCount <= 1) return;
      final next = (_dealIndex + 1) % _dealCount;
      _dealController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _dealIndex = next;
    });
  }

  @override
  void dispose() {
    _dealTimer?.cancel();
    _searchController.dispose();
    _dealController.dispose();
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
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
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

  List<ListingModel> _searchResults(List<ListingModel> items) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return items.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.city.toLowerCase().contains(query);
    }).toList();
  }

  List<ListingModel> _recommendations(
    List<ListingModel> items,
    List<OrderModel> orders,
  ) {
    final interests = orders
        .map((o) => o.productCategory.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toSet();

    final scored = [...items];
    scored.sort((a, b) {
      int score(ListingModel item) {
        var result = item.soldCount * 3 + item.rating.round() * 5;
        if (interests.contains(item.category.toLowerCase())) result += 100;
        if (item.hasActiveDeal) result += 8;
        return result;
      }

      return score(b).compareTo(score(a));
    });
    return scored;
  }

  bool _isNearby(ListingModel listing) {
    if (_locationLoading || _cityName == 'Choose location') return true;
    if (listing.city.trim().isEmpty) return true;
    return listing.city.trim().toLowerCase() == _cityName.trim().toLowerCase();
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
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load listings: $e'),
            ),
          ),
          data: (items) {
            final nearby = items.where(_isNearby).toList();
            final trending = [...nearby]
              ..sort((a, b) {
                final sold = b.soldCount.compareTo(a.soldCount);
                if (sold != 0) return sold;
                return b.rating.compareTo(a.rating);
              });
            final deals = nearby.where((e) => e.hasActiveDeal).toList();
            final searchResults = _searchResults(items);
            _dealCount = deals.length;

            return Column(
              children: [
                _header(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _search(),
                      if (_searchText.isEmpty) ...[
                        _dealCarousel(deals),
                        _section(
                          'Trending Near You',
                          trending.take(6).toList(),
                          onSeeAll: () => context.push('/marketplace'),
                        ),
                        if (user == null)
                          _section(
                            'Based on Your Interest',
                            items.take(6).toList(),
                            onSeeAll: () =>
                                context.push('/marketplace?mode=interest'),
                          )
                        else
                          StreamBuilder<List<OrderModel>>(
                            stream: OrderService().getBuyerOrders(user.uid),
                            builder: (_, snapshot) {
                              final recs = _recommendations(
                                items,
                                snapshot.data ?? const <OrderModel>[],
                              );
                              return _section(
                                'Based on Your Interest',
                                recs.take(6).toList(),
                                onSeeAll: () =>
                                    context.push('/marketplace?mode=interest'),
                              );
                            },
                          ),
                        _localBrands(items),
                      ] else
                        _searchGrid(searchResults),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header() {
    return Container(
      color: navy,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'BRAND\nNEXT DOOR',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'serif',
                fontSize: 15,
                height: .95,
                letterSpacing: 3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _search() {
    return Container(
      color: navy,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discover something\nextraordinary nearby.',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'serif',
              fontSize: 25,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchText = value),
            decoration: InputDecoration(
              hintText: 'Search brands & products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchText = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
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
                Flexible(
                  child: Text(
                    _cityName,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dealCarousel(List<ListingModel> deals) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Top Deals Near Me',
                  style: TextStyle(
                    color: navy,
                    fontFamily: 'serif',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (deals.length > 4)
                TextButton(
                  onPressed: () => context.push('/marketplace?mode=deals'),
                  child: const Text('See All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (deals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('No active deals nearby yet.'),
            )
          else
            SizedBox(
              height: 178,
              child: PageView.builder(
                controller: _dealController,
                itemCount: deals.length,
                onPageChanged: (index) => _dealIndex = index,
                itemBuilder: (_, i) {
                  final listing = deals[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () =>
                          context.push('/listing-details', extra: listing),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE6DED2)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 135,
                              height: double.infinity,
                              child: listing.images.isNotEmpty
                                  ? Image.network(
                                      listing.images.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image_outlined),
                                    )
                                  : const Icon(Icons.image_outlined, size: 42),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: gold.withValues(alpha: .18),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${listing.discountPercent}% OFF',
                                        style: const TextStyle(
                                          color: navy,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      listing.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: navy,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          '\$${listing.currentPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: navy,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Flexible(
                                          child: Text(
                                            '\$${listing.price.toStringAsFixed(2)}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    List<ListingModel> items, {
    VoidCallback? onSeeAll,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: const Text('See All')),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 225,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(
                width: 155,
                child: ProductCard(listing: items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _localBrands(List<ListingModel> items) {
    final byBrand = <String, ListingModel>{};
    for (final item in items) {
      if (item.brandId.trim().isEmpty) continue;
      byBrand.putIfAbsent(item.brandId, () => item);
    }
    final brands = byBrand.values.take(8).toList();
    if (brands.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Local Brands',
            style: TextStyle(
              color: navy,
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Discover independent sellers near you.',
            style: TextStyle(color: Color(0xFF7A858B), fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: brands.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) => SizedBox(
                width: 220,
                child: _LocalBrandCard(listing: brands[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchGrid(List<ListingModel> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Results',
            style: TextStyle(
              color: navy,
              fontFamily: 'serif',
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('No items found.')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: .68,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
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
        if (index == 0) return;
        if (index == 1) context.push('/marketplace');
        if (index == 2) context.push('/buyer-orders');
        if (index == 3) context.push('/settings?role=buyer');
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _LocalBrandCard extends StatefulWidget {
  final ListingModel listing;

  const _LocalBrandCard({required this.listing});

  @override
  State<_LocalBrandCard> createState() => _LocalBrandCardState();
}

class _LocalBrandCardState extends State<_LocalBrandCard> {
  static const _navy = Color(0xFF0C2430);
  Map<String, dynamic>? brand;

  @override
  void initState() {
    super.initState();
    _loadBrand();
  }

  Future<void> _loadBrand() async {
    try {
      final result = await BrandService().getBrand(widget.listing.brandId);
      if (mounted) setState(() => brand = result);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final name = (brand?['brandName'] ?? 'Local Brand').toString();
    final description = (brand?['description'] ?? brand?['tagline'] ?? '').toString();
    final logoUrl = (brand?['logoUrl'] ?? '').toString();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(
          '/seller-storefront',
          extra: {
            'sellerId': widget.listing.sellerId,
            'brandId': widget.listing.brandId,
          },
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE7DED2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFF1E6D4),
                    backgroundImage:
                        logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                    child: logoUrl.isEmpty
                        ? const Icon(Icons.storefront_outlined, color: _navy)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _navy,
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  description.isEmpty
                      ? 'Explore products from this local seller.'
                      : description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6E797F),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text(
                    'View Store',
                    style: TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 16, color: _navy),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
