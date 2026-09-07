import 'package:flutter/material.dart';

import '../../../models/listing_model.dart';
import '../../reviews/services/review_service.dart';
import '../../reviews/widgets/reviews_preview.dart';
import '../widgets/brand_info_card.dart';
import '../widgets/buy_now_section.dart';
import '../widgets/delivery_info_card.dart';
import '../widgets/listing_image_section.dart';
import '../widgets/listing_price_card.dart';

class ListingDetailsScreen extends StatelessWidget {
  final ListingModel listing;

  const ListingDetailsScreen({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
      ),
      bottomNavigationBar: BuyNowSection(
        listing: listing,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListingImageSection(images: listing.images),
            const SizedBox(height: 24),
            Text(
              listing.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(listing.category)),
                if (listing.city.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.location_on_outlined, size: 16),
                    label: Text(listing.city),
                  ),
                if (listing.hasActiveDeal)
                  Chip(
                    avatar: const Icon(Icons.local_offer_outlined, size: 16),
                    label: Text('${listing.discountPercent}% off'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            BrandInfoCard(brandId: listing.brandId),
            const SizedBox(height: 24),
            if (listing.hasActiveDeal) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFFE14DAD)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Hot Deal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '\$${listing.currentPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
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
              ),
              const SizedBox(height: 14),
            ],
            ListingPriceCard(
              price: listing.currentPrice,
              category: listing.category,
              status: listing.status,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      listing.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            DeliveryInfoCard(
              deliveryAvailable: listing.deliveryAvailable,
              pickupAvailable: listing.pickupAvailable,
              city: listing.city.isEmpty ? null : listing.city,
            ),
            const SizedBox(height: 24),
            ReviewsPreview(
              title: 'Item Reviews',
              reviews: ReviewService().getListingReviews(listing.listingId),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
