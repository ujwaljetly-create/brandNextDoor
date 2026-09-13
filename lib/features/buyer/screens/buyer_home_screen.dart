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
  final _dealController = PageController(viewportFraction: .91);
  Timer? _dealTimer;

  String _searchText = '';
  String _cityName = 'Finding your location...';
  bool _locationLoading = true;
  String _selectedCategory = 'All';
  int _dealIndex = 0;
  int _dealCount = 0;

  final List<(String, IconData, String)> _quickCategories = const [
    ('All', Icons.grid_view_rounded, 'All'),
    ('Women', Icons.checkroom_outlined, 'Fashion'),
    ('Men', Icons.person_outline, 'Fashion'),
    ('Home', Icons.chair_outlined, 'Home Decor'),
    ('Beauty', Icons.spa_outlined, 'Beauty'),
    ('Food', Icons.restaurant_outlined, 'Food'),
  ];

  final List<String> _allCategories = const [
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

  bool _matchesCategory(ListingModel item) {
    if (_selectedCategory == 'All') return true;
    final actual = item.category.toLowerCase();
    final selected = _selectedCategory.toLowerCase();
    if (selected == 'fashion') {
      return actual.contains('fashion') ||
          actual.contains('women') ||
          actual.contains('men');
    }
    if (selected == 'home decor') {
      return actual.contains('home') || actual.contains('decor');
    }
    return actual == selected || actual.contains(selected);
  }

  List<ListingModel> _filter(List<ListingModel> items) {
    final query = _searchText.trim().toLowerCase();
    return items.where((item) {
      final matchSearch = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.city.toLowerCase().contains(query);
      return matchSearch && _matchesCategory(item);
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
        return result;
      }

      return score(b).compareTo(score(a));
    });
    return scored;
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
              const Text(
                'Browse Categories',
                style: TextStyle(
                  color: navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allCategories.map((category) {
                  final active = _selectedCategory == category;
                  return ChoiceChip(
                    selected: active,
                    selectedColor: navy,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : navy,
                    ),
                    label: Text(category),
                    onSelected: (_) => Navigator.pop(context, category),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );

    if (value != null && mounted) {
      setState(() => _selectedCategory = value);
    }
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
            final filtered = _filter(items);
            final nearby = items.where((item) {
              return _locationLoading ||
                  _cityName == 'Choose location' ||
                  item.city.trim().isEmpty ||
                  item.city.toLowerCase() == _cityName.toLowerCase();
            }).toList();
            final trending = [...nearby]
              ..sort((a, b) => b.soldCount.compareTo(a.soldCount));
            final deals = nearby.where((item) => item.hasActiveDeal).toList();
            _dealCount = deals.length;

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
                            onSeeAll: () => context.push('/marketplace?mode=interest'),
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
                      ],
                      _discover(filtered),
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

  Widget _header() => Container(
        color: navy,
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
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
              onPressed: () {},
              icon: const Icon(Icons.notifications_none, color: Colors.white),
            ),
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

  Widget _search() => Container(
        color: navy,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
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

  Widget _categories() => Container(
        color: navy,
        height: 78,
        padding: const EdgeInsets.fromLTRB(14, 5, 14, 10),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _quickCategories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (_, i) {
            if (i == _quickCategories.length) {
              return _categoryButton(
                'More',
                Icons.more_horiz,
                false,
                _showMoreCategories,
              );
            }
            final data = _quickCategories[i];
            final active = _selectedCategory == data.$3 ||
                (_selectedCategory == 'All' && data.$1 == 'All');
            return _categoryButton(
              data.$1,
              data.$2,
              active,
              () => setState(() => _selectedCategory = data.$3),
            );
          },
        ),
      );

  Widget _categoryButton(
    String label,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) =>
      SizedBox(
        width: 65,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: active ? const Color(0xFFE8D4B8) : const Color(0xFF183543),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: active ? navy : Colors.white, size: 21),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? navy : Colors.white,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _dealCarousel(List<ListingModel> deals) => Padding(
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
                        onTap: () => context.push(
                          '/listing-details',
                          extra: listing,
                        ),
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
                                                decoration: TextDecoration.lineThrough,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (listing.city.isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Text(
                                          listing.city,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFF6D777C),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
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
            height: 230,
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

  Widget _discover(List<ListingModel> items) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _searchText.isNotEmpty
                  ? 'Search Results'
                  : (_selectedCategory == 'All'
                      ? 'Discover Local Brands'
                      : _selectedCategory),
              style: const TextStyle(
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
                child: Center(child: Text('No items found for this category.')),
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

  Widget _bottomNav() => NavigationBar(
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
