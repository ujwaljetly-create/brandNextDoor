import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../brand/services/brand_service.dart';
import '../../listings/services/listing_service.dart';
import '../../reviews/services/review_service.dart';
import '../../reviews/widgets/reviews_preview.dart';
import '../widgets/product_card.dart';

class SellerStorefrontScreen extends StatefulWidget {
  final String sellerId;
  final String brandId;

  const SellerStorefrontScreen({
    super.key,
    required this.sellerId,
    required this.brandId,
  });

  @override
  State<SellerStorefrontScreen> createState() => _SellerStorefrontScreenState();
}

class _SellerStorefrontScreenState extends State<SellerStorefrontScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  bool isLoading = true;
  Map<String, dynamic>? brand;

  @override
  void initState() {
    super.initState();
    _loadBrand();
  }

  Future<void> _loadBrand() async {
    try {
      final result = widget.brandId.isNotEmpty
          ? await BrandService().getBrand(widget.brandId)
          : null;
      if (!mounted) return;
      setState(() {
        brand = result;
        isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandName = (brand?['brandName'] ?? 'Local Brand').toString();
    final tagline = (brand?['tagline'] ?? '').toString();
    final description = (brand?['description'] ?? '').toString();
    final logoUrl = (brand?['logoUrl'] ?? '').toString();
    final bannerUrl = (brand?['bannerUrl'] ?? '').toString();
    final city = (brand?['city'] ?? '').toString();
    final rating = (brand?['rating'] ?? 0).toDouble();
    final reviews = (brand?['totalReviews'] ?? 0) as num;

    return Scaffold(
      backgroundColor: _cream,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ListingModel>>(
              stream: ListingService().getActiveSellerListings(widget.sellerId),
              builder: (context, snapshot) {
                final listings = snapshot.data ?? const <ListingModel>[];
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 240,
                      backgroundColor: _cream,
                      leading: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      actions: [
                        IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined, color: Colors.white)),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            bannerUrl.isNotEmpty
                                ? Image.network(bannerUrl, fit: BoxFit.cover)
                                : Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF6A4D35), Color(0xFFC7A57A)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                            Container(color: Colors.black.withValues(alpha: .15)),
                            Center(
                              child: Text(
                                brandName.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                        child: Column(
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -38),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: Colors.white,
                                backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                                child: logoUrl.isEmpty ? const Text('BN', style: TextStyle(color: _navy, fontFamily: 'serif', fontSize: 24)) : null,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -24),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(child: Text(brandName.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: _navy, fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.w700))),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: const Color(0xFFDDF2E7), borderRadius: BorderRadius.circular(16)),
                                        child: const Text('✓ Verified Local Brand', style: TextStyle(color: Color(0xFF236948), fontSize: 10, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                  if (city.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.location_on_outlined, size: 16), const SizedBox(width: 4), Text(city)]),
                                  ],
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(description, textAlign: TextAlign.center, style: const TextStyle(color: _navy, height: 1.45)),
                                  ] else if (tagline.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(tagline, textAlign: TextAlign.center, style: const TextStyle(color: _navy)),
                                  ],
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _metric(rating > 0 ? rating.toStringAsFixed(1) : 'New', 'Rating'),
                                      _metric(reviews.toInt().toString(), 'Reviews'),
                                      _metric(listings.length.toString(), 'Products'),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(backgroundColor: _navy),
                                          onPressed: () {},
                                          child: const Text('Follow'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => context.push('/messages'),
                                          icon: const Icon(Icons.chat_bubble_outline),
                                          label: const Text('Message'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Expanded(child: _StoreTab('Products', true)),
                                Expanded(child: _StoreTab('About', false)),
                                Expanded(child: _StoreTab('Reviews', false)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (listings.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(30),
                                child: Text('No active products right now.'),
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
                            const SizedBox(height: 22),
                            ReviewsPreview(
                              title: 'Seller Reviews',
                              reviews: ReviewService().getSellerReviews(widget.sellerId),
                              sellerRating: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _metric(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFF7A858B), fontSize: 11)),
        ],
      );
}

class _StoreTab extends StatelessWidget {
  final String label;
  final bool active;
  const _StoreTab(this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
        const SizedBox(height: 8),
        Container(height: 2, color: active ? const Color(0xFFC99245) : Colors.transparent),
      ],
    );
  }
}
