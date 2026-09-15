import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../../services/location/city_location_service.dart';
import '../../../widgets/city_picker_sheet.dart';
import '../../../widgets/notification_bell.dart';
import '../../brand/services/brand_service.dart';
import '../providers/buyer_home_provider.dart';
import '../widgets/product_card.dart';

class BuyerHomeScreen extends ConsumerStatefulWidget {
  const BuyerHomeScreen({super.key});
  @override
  ConsumerState<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends ConsumerState<BuyerHomeScreen> {
  static const navy = Color(0xFF0C2430), gold = Color(0xFFC99245), cream = Color(0xFFF8F3EA);
  final _searchController = TextEditingController();
  final _locationService = CityLocationService();
  String _searchText = '', _cityName = 'Finding your location...';
  bool _locationLoading = true;

  @override
  void initState() { super.initState(); _loadCurrentCity(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _loadCurrentCity() async {
    try {
      final result = await _locationService.currentCity();
      if (mounted) setState(() { _cityName = result?.city ?? 'Choose location'; _locationLoading = false; });
    } catch (_) { if (mounted) setState(() { _cityName = 'Choose location'; _locationLoading = false; }); }
  }

  Future<void> _changeLocation() async {
    final result = await CityPickerSheet.show(context, initialCity: _locationLoading || _cityName == 'Choose location' ? '' : _cityName);
    if (result != null && mounted) setState(() { _cityName = result.city; _locationLoading = false; });
  }

  bool _near(ListingModel item) => _locationLoading || _cityName == 'Choose location' || item.city.trim().isEmpty || item.city.trim().toLowerCase() == _cityName.trim().toLowerCase();
  bool _matches(ListingModel item) {
    final q = _searchText.trim().toLowerCase();
    return q.isEmpty || item.title.toLowerCase().contains(q) || item.category.toLowerCase().contains(q) || item.description.toLowerCase().contains(q) || item.city.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(buyerListingsProvider);
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(child: listings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load listings: $e')),
        data: (all) {
          final nearby = all.where(_near).toList();
          final search = all.where(_matches).toList();
          final trending = [...nearby]..sort((a, b) { final sold = b.soldCount.compareTo(a.soldCount); return sold != 0 ? sold : b.rating.compareTo(a.rating); });
          final deals = nearby.where((e) => e.hasActiveDeal).toList();
          return ListView(children: [
            _header(), _searchHeader(),
            if (_searchText.isNotEmpty) _grid(search) else ...[
              _deals(deals),
              _section('Trending Near You', trending.take(8).toList()),
              _section('Based on Your Interest', nearby.take(8).toList()),
              _localBrands(nearby),
            ],
            const SizedBox(height: 30),
          ]);
        },
      )),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 0,
        onDestinationSelected: (i) { if (i == 1) context.push('/marketplace'); if (i == 2) context.push('/buyer-orders'); if (i == 3) context.push('/settings?role=buyer'); },
        destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'), NavigationDestination(icon: Icon(Icons.search), label: 'Explore'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'), NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile')],
      ),
    );
  }

  Widget _header() => Container(color: navy, padding: const EdgeInsets.fromLTRB(18, 14, 10, 8), child: Row(children: [
    const Expanded(child: Text('BRAND\nNEXT DOOR', style: TextStyle(color: Colors.white, fontFamily: 'serif', fontSize: 15, height: .95, letterSpacing: 3, fontWeight: FontWeight.w700))),
    NotificationBell(onPressed: () => context.push('/notifications')),
  ]));

  Widget _searchHeader() => Container(color: navy, padding: const EdgeInsets.fromLTRB(18, 0, 18, 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Discover something\nextraordinary nearby.', style: TextStyle(color: Colors.white, fontFamily: 'serif', fontSize: 25, height: 1.05)), const SizedBox(height: 14),
    TextField(controller: _searchController, onChanged: (v) => setState(() => _searchText = v), decoration: InputDecoration(hintText: 'Search brands & products...', prefixIcon: const Icon(Icons.search), suffixIcon: _searchText.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() => _searchText = ''); }, icon: const Icon(Icons.close)), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none))),
    const SizedBox(height: 9), InkWell(onTap: _changeLocation, child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.location_on_outlined, color: gold, size: 17), const SizedBox(width: 5), Flexible(child: Text(_cityName, style: const TextStyle(color: Colors.white70, fontSize: 12))), const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16)])),
  ]));

  Widget _deals(List<ListingModel> deals) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 0, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Top Deals Near Me', style: TextStyle(color: navy, fontFamily: 'serif', fontSize: 21, fontWeight: FontWeight.w700)), const SizedBox(height: 10),
    if (deals.isEmpty) Container(margin: const EdgeInsets.only(right: 16), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Text('No active deals nearby yet.'))
    else SizedBox(height: 225, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: deals.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) => SizedBox(width: 155, child: ProductCard(listing: deals[i])))),
  ]));

  Widget _section(String title, List<ListingModel> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.fromLTRB(16, 22, 0, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(title, style: const TextStyle(color: navy, fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700))), TextButton(onPressed: () => context.push('/marketplace'), child: const Text('See All')), const SizedBox(width: 8)]),
      const SizedBox(height: 8), SizedBox(height: 225, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) => SizedBox(width: 155, child: ProductCard(listing: items[i])))),
    ]));
  }

  Widget _grid(List<ListingModel> items) => Padding(padding: const EdgeInsets.all(16), child: items.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('No matching products found.'))) : GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .68, crossAxisSpacing: 12, mainAxisSpacing: 12), itemBuilder: (_, i) => ProductCard(listing: items[i])));

  Widget _localBrands(List<ListingModel> items) {
    final byBrand = <String, ListingModel>{};
    for (final item in items) { if (item.brandId.trim().isNotEmpty) byBrand.putIfAbsent(item.brandId, () => item); }
    final brands = byBrand.values.take(8).toList();
    if (brands.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.fromLTRB(16, 24, 0, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Local Brands Near You', style: TextStyle(color: navy, fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 4), const Text('Discover independent sellers in your area.', style: TextStyle(color: Color(0xFF7A858B))), const SizedBox(height: 12),
      SizedBox(height: 150, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: brands.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) => _brandCard(brands[i]))),
    ]));
  }

  Widget _brandCard(ListingModel listing) => FutureBuilder<Map<String, dynamic>?>(future: BrandService().getBrand(listing.brandId), builder: (context, snapshot) {
    final brand = snapshot.data;
    final name = (brand?['brandName'] ?? '').toString().trim();
    final logo = (brand?['logoUrl'] ?? '').toString().trim();
    if (snapshot.connectionState == ConnectionState.done && (name.isEmpty || name.toLowerCase() == 'local brand')) return const SizedBox.shrink();
    return InkWell(onTap: () => context.push('/seller-storefront?sellerId=${listing.sellerId}&brandId=${listing.brandId}'), child: Container(width: 135, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE6DED2))), child: Column(children: [CircleAvatar(radius: 36, backgroundColor: const Color(0xFFF1E7D8), backgroundImage: logo.isNotEmpty ? NetworkImage(logo) : null, child: logo.isEmpty ? const Icon(Icons.storefront_outlined, color: navy) : null), const SizedBox(height: 9), Text(name.isEmpty ? 'Loading...' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: navy, fontWeight: FontWeight.w700)), if (listing.city.isNotEmpty) Text(listing.city, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF7A858B), fontSize: 11))])));
  });
}
