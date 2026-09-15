import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../brand/services/brand_service.dart';
import '../../listings/services/listing_service.dart';

class BrandInfoCard extends StatefulWidget {
  final String brandId;
  final String sellerId;
  final String currentListingId;

  const BrandInfoCard({
    super.key,
    required this.brandId,
    required this.sellerId,
    required this.currentListingId,
  });

  @override
  State<BrandInfoCard> createState() => _BrandInfoCardState();
}

class _BrandInfoCardState extends State<BrandInfoCard> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);

  bool isLoading = true;
  bool hasMoreItems = false;
  Map<String, dynamic>? brand;

  @override
  void initState() {
    super.initState();
    loadBrand();
  }

  Future<void> loadBrand() async {
    try {
      final result = await BrandService().getBrand(widget.brandId);
      final listings = await ListingService()
          .getActiveSellerListings(widget.sellerId)
          .first;

      if (!mounted) return;
      setState(() {
        brand = result;
        hasMoreItems = listings.any(
          (listing) => listing.listingId != widget.currentListingId,
        );
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (brand == null) return const SizedBox.shrink();

    final logoUrl = (brand!['logoUrl'] ?? '').toString();
    final brandName = (brand!['brandName'] ?? 'Seller').toString();
    final tagline = (brand!['tagline'] ?? '').toString();
    final rating = (brand!['rating'] ?? 0).toDouble();
    final totalReviews = brand!['totalReviews'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFF1E8DB),
                backgroundImage: logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
                child: logoUrl.isEmpty
                    ? const Icon(Icons.storefront_outlined, color: _navy, size: 30)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      brandName,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (tagline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF68757B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.star, color: _gold, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '($totalReviews reviews)',
                          style: const TextStyle(
                            color: Color(0xFF7A858B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasMoreItems) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.push(
                '/seller-storefront',
                extra: {
                  'sellerId': widget.sellerId,
                  'brandId': widget.brandId,
                },
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.storefront_outlined, color: _gold, size: 20),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'More from this Seller',
                        style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: _navy),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
