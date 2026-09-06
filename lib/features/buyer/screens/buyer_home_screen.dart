import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
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

  Timer? _dealTimer;
  String _searchText = '';
  String _cityName = 'Finding your location...';
  bool _locationLoading = true;
  int _currentDealIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentCity();
    _dealTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_dealsController.hasClients) return;

      final pageCount = _currentDealCount;
      if (pageCount <= 1) return;

      _currentDealIndex = (_currentDealIndex + 1) % pageCount;
      _dealsController.animateToPage(
        _currentDealIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  int _currentDealCount = 0;

  @override
  void dispose() {
    _dealTimer?.cancel();
    _searchController.dispose();
    _dealsController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentCity() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        setState(() {
          _cityName = 'Choose location';
          _locationLoading = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _cityName = 'Choose location';
          _locationLoading = false;
        });
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
      if (!mounted) return;
      setState(() {
        _cityName = 'Choose location';
        _locationLoading = false;
      });
    }
  }

  Future<void> _changeLocation() async {
    final controller = TextEditingController(
      text: _cityName == 'Choose location' || _locationLoading ? '' : _cityName,
    );

    final city = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
              onPressed: () async {
                Navigator.pop(dialogContext, '__current__');
              },
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
        );
      },
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

  List<ListingModel> _filterListings(List<ListingModel> items) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return items;

    return items.where((listing) {
      return listing.title.toLowerCase().contains(query) ||
          listing.category.toLowerCase().contains(query) ||
          listing.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(buyerListingsProvider);

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
          final hotDeals = items.take(6).toList();
          _currentDealCount = hotDeals.length;

          if (_currentDealIndex >= hotDeals.length && hotDeals.isNotEmpty) {
            _currentDealIndex = 0;
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
              const SizedBox(height: 24),
              if (_searchText.isEmpty && hotDeals.isNotEmpty) ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Hot deals near me',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/marketplace');
                      },
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 178,
                  child: PageView.builder(
                    controller: _dealsController,
                    itemCount: hotDeals.length,
                    onPageChanged: (index) {
                      _currentDealIndex = index;
                    },
                    itemBuilder: (context, index) {
                      final deal = hotDeals[index];

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            context.push(
                              '/listing-details',
                              extra: deal,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF7B61FF),
                                  Color(0xFFE14DAD),
                                ],
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (deal.images.isNotEmpty)
                                    Opacity(
                                      opacity: 0.32,
                                      child: Image.network(
                                        deal.images.first,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox.shrink(),
                                      ),
                                    ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Color(0xAA3B145F),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.92,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _locationLoading
                                                ? 'Hot near you'
                                                : 'Hot in $_cityName',
                                            style: const TextStyle(
                                              color: Color(0xFF6D28D9),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          deal.title,
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
                                            Expanded(
                                              child: Text(
                                                deal.category,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              '\$${deal.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold,
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
                    },
                  ),
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
                  child: Center(
                    child: Text('No listings found.'),
                  ),
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
                    return ProductCard(
                      listing: filteredItems[index],
                    );
                  },
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
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
}
