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
  final TextEditingController _searchController = TextEditingController();
  final PageController _dealsController = PageController(viewportFraction: 0.88);
  final PageController _topSellingController =
      PageController(viewportFraction: 0.88);

  Timer? _carouselTimer;
  String _searchText = '';
  String _cityName = 'Finding your location...';
  bool _locationLoading = true;
  int _currentDealIndex = 0;
  int _currentTopIndex = 0;
  int _currentDealCount = 0;
  int _currentTopCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentCity();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _advanceCarousel(
        controller: _dealsController,
        count: _currentDealCount,
        current: _currentDealIndex,
        onIndex: (value) => _currentDealIndex = value,
      );
      _advanceCarousel(
        controller: _topSellingController,
        count: _currentTopCount,
        current: _currentTopIndex,
        onIndex: (value) => _currentTopIndex = value,
      );
    });
  }

  void _advanceCarousel({
    required PageController controller,
    required int count,
    required int current,
    required ValueChanged<int> onIndex,
  }) {
    if (!controller.hasClients || count <= 1) return;
    final next = (current + 1) % count;
    onIndex(next);
    controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _searchController.dispose();
    _dealsController.dispose();
    _topSellingController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentCity() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _setCityFallback();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setCityFallback();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
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
          decoration: const InputDecoration(
            labelText: 'City name',
            prefixIcon: Icon(Icons.location_city_outlined),
          ),
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
              if (value.isNotEmpty) {
                Navigator.pop(dialogContext, value);
              }
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
      return;
    }

    setState(() {
      _cityName = city;
      _locationLoading = false;
    });
  }

  bool _matchesCurrentCity(ListingModel listing) {
    if (_locationLoading || _cityName == 'Choose location') return true;
    if (listing.city.trim().isEmpty) return false;
    return listing.city.trim().toLowerCase() == _cityName.trim().toLowerCase();
  }

  List<ListingModel> _filterListings(List<ListingModel> items) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((listing) {
      return listing.title.toLowerCase().contains(query) ||
          listing.category.toLowerCase().contains(query) ||
          listing.description.toLowerCase().contains(query) ||
          listing.city.toLowerCase().contains(query);
    }).toList();
  }

  List<ListingModel> _interestItems(
    List<ListingModel> items,
    List<OrderModel> orders,
  ) {
    final categories = orders
        .where((order) => order.status == 'delivered')
        .map((order) => order.productCategory.trim().toLowerCase())
        .where((category) => category.isNotEmpty)
        .toSet();

    final recommendations = categories.isEmpty
        ? [...items]
        : items
            .where(
              (listing) => categories.contains(listing.category.toLowerCase()),
            )
            .toList();

    recommendations.sort((a, b) {
      final ratingCompare = b.rating.compareTo(a.rating);
      if (ratingCompare != 0) return ratingCompare;
      return b.soldCount.compareTo(a.soldCount);
    });

    return recommendations.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(buyerListingsProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _changeLocation,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, size: 21),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _cityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.keyboard_arrow_down, size: 21),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              context.push('/settings?role=buyer');
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: listings.when(
        data: (items) {
          final filteredItems = _filterListings(items);
          final hotDeals = items
              .where((listing) => listing.hasActiveDeal)
              .where(_matchesCurrentCity)
              .take(6)
              .toList();
          final topSelling = items.where((listing) => listing.soldCount > 0).toList()
            ..sort((a, b) => b.soldCount.compareTo(a.soldCount));
          final topSellingItems = topSelling.take(6).toList();

          _currentDealCount = hotDeals.length;
          _currentTopCount = topSellingItems.length;

          if (_currentDealIndex >= hotDeals.length && hotDeals.isNotEmpty) {
            _currentDealIndex = 0;
          }
          if (_currentTopIndex >= topSellingItems.length &&
              topSellingItems.isNotEmpty) {
            _currentTopIndex = 0;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search food, products, services...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchText = '';
                            });
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                ),
              ),
              if (_searchText.isEmpty) ...[
                const SizedBox(height: 24),
                _sectionHeader(
                  title: 'Hot deals near me',
                  action: 'See all',
                  onTap: () => context.push('/marketplace'),
                ),
                const SizedBox(height: 12),
                if (hotDeals.isEmpty)
                  _emptySection(
                    'No active hot deals in $_cityName yet.',
                  )
                else
                  SizedBox(
                    height: 190,
                    child: PageView.builder(
                      controller: _dealsController,
                      itemCount: hotDeals.length,
                      onPageChanged: (index) {
                        _currentDealIndex = index;
                      },
                      itemBuilder: (context, index) => _DealCard(
                        listing: hotDeals[index],
                        cityName: _cityName,
                      ),
                    ),
                  ),
                const SizedBox(height: 26),
                _sectionHeader(title: 'Top selling items'),
                const SizedBox(height: 12),
                if (topSellingItems.isEmpty)
                  _emptySection(
                    'Top selling items will appear after completed orders.',
                  )
                else
                  SizedBox(
                    height: 178,
                    child: PageView.builder(
                      controller: _topSellingController,
                      itemCount: topSellingItems.length,
                      onPageChanged: (index) {
                        _currentTopIndex = index;
                      },
                      itemBuilder: (context, index) => _TopSellingCard(
                        listing: topSellingItems[index],
                      ),
                    ),
                  ),
                const SizedBox(height: 26),
                _sectionHeader(title: 'Based on your interest'),
                const SizedBox(height: 12),
                if (user == null)
                  _interestStrip(items.take(8).toList())
                else
                  StreamBuilder<List<OrderModel>>(
                    stream: OrderService().getBuyerOrders(user.uid),
                    builder: (context, snapshot) {
                      final recommendations = _interestItems(
                        items,
                        snapshot.data ?? const <OrderModel>[],
                      );
                      return _interestStrip(recommendations);
                    },
                  ),
                const SizedBox(height: 26),
              ],
              Text(
                _searchText.isEmpty ? 'Discover local brands' : 'Search results',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (filteredItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Text('No listings found.')),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredItems.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: .72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    return ProductCard(listing: filteredItems[index]);
                  },
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load listings: $e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    String? action,
    VoidCallback? onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(action),
          ),
      ],
    );
  }

  Widget _emptySection(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.local_offer_outlined),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Widget _interestStrip(List<ListingModel> items) {
    if (items.isEmpty) {
      return _emptySection('Recommendations will appear as you shop.');
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final listing = items[index];
          return SizedBox(
            width: 150,
            child: _RecommendationCard(listing: listing),
          );
        },
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final ListingModel listing;
  final String cityName;

  const _DealCard({
    required this.listing,
    required this.cityName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          context.push('/listing-details', extra: listing);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7B61FF), Color(0xFFE14DAD)],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (listing.images.isNotEmpty)
                  Opacity(
                    opacity: 0.30,
                    child: Image.network(
                      listing.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB83B145F)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${listing.discountPercent}% OFF',
                              style: const TextStyle(
                                color: Color(0xFF6D28D9),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            listing.city.isNotEmpty ? listing.city : cityName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '\$${listing.currentPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${listing.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopSellingCard extends StatelessWidget {
  final ListingModel listing;

  const _TopSellingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/listing-details', extra: listing),
          child: Row(
            children: [
              SizedBox(
                width: 140,
                height: double.infinity,
                child: listing.images.isNotEmpty
                    ? Image.network(
                        listing.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_outlined, size: 44),
                      )
                    : const Icon(Icons.image_outlined, size: 44),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'TOP SELLER',
                        style: TextStyle(
                          color: Color(0xFF7B61FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${listing.soldCount} sold'),
                      const SizedBox(height: 8),
                      Text(
                        '\$${listing.currentPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
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
  }
}

class _RecommendationCard extends StatelessWidget {
  final ListingModel listing;

  const _RecommendationCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/listing-details', extra: listing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 105,
              width: double.infinity,
              child: listing.images.isNotEmpty
                  ? Image.network(
                      listing.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_outlined),
                    )
                  : const Icon(Icons.image_outlined),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '\$${listing.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (listing.rating > 0) ...[
                        const Icon(Icons.star, size: 15, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(listing.rating.toStringAsFixed(1)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
