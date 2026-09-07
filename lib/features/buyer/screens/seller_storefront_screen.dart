import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../brand/services/brand_service.dart';
import '../../listings/services/listing_service.dart';
import '../../reviews/services/review_service.dart';
import '../../reviews/widgets/reviews_preview.dart';

class SellerStorefrontScreen extends StatefulWidget {
  final String sellerId;
  final String brandId;

  const SellerStorefrontScreen({
    super.key,
    required this.sellerId,
    required this.brandId,
  });

  @override
  State<SellerStorefrontScreen> createState() =>
      _SellerStorefrontScreenState();
}

class _SellerStorefrontScreenState extends State<SellerStorefrontScreen> {
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
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandName = (brand?['brandName'] ?? 'Seller').toString();
    final tagline = (brand?['tagline'] ?? '').toString();
    final description = (brand?['description'] ?? '').toString();
    final logoUrl = (brand?['logoUrl'] ?? '').toString();
    final rating = (brand?['rating'] ?? 0).toDouble();
    final totalReviews = (brand?['totalReviews'] ?? 0) as num;

    return Scaffold(
      appBar: AppBar(
        title: Text(brandName),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ListingModel>>(
              stream: ListingService().getActiveSellerListings(widget.sellerId),
              builder: (context, snapshot) {
                final listings = snapshot.data ?? const <ListingModel>[];

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundImage: logoUrl.isNotEmpty
                                  ? NetworkImage(logoUrl)
                                  : null,
                              child: logoUrl.isEmpty
                                  ? const Icon(Icons.storefront, size: 40)
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              brandName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (rating > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('(${totalReviews.toInt()} reviews)'),
                                ],
                              ),
                            ],
                            if (tagline.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                tagline,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                description,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    ReviewsPreview(
                      title: 'Seller Reviews',
                      reviews: ReviewService().getSellerReviews(widget.sellerId),
                      sellerRating: true,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Available Listings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text('${listings.length}'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        listings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (listings.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'This seller has no active listings right now.',
                          ),
                        ),
                      )
                    else
                      ...listings.map(
                        (listing) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              context.push(
                                '/listing-details',
                                extra: listing,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: listing.images.isNotEmpty
                                        ? Image.network(
                                            listing.images.first,
                                            width: 84,
                                            height: 84,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _listingPlaceholder(),
                                          )
                                        : _listingPlaceholder(),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          listing.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(listing.category),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              '\$${listing.currentPrice.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                            if (listing.rating > 0) ...[
                                              const Spacer(),
                                              const Icon(
                                                Icons.star,
                                                size: 16,
                                                color: Colors.amber,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                listing.rating
                                                    .toStringAsFixed(1),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _listingPlaceholder() {
    return Container(
      width: 84,
      height: 84,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image_outlined),
    );
  }
}
