import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../reviews/services/review_service.dart';
import '../../reviews/widgets/reviews_preview.dart';
import '../widgets/brand_info_card.dart';
import '../widgets/listing_image_section.dart';

class ListingDetailsScreen extends StatelessWidget {
  final ListingModel listing;

  const ListingDetailsScreen({super.key, required this.listing});

  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: _navy),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined, color: _navy)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border, color: _navy)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          ListingImageSection(images: listing.images),
          const SizedBox(height: 18),
          BrandInfoCard(brandId: listing.brandId),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: const TextStyle(
                        color: _navy,
                        fontFamily: 'serif',
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (listing.rating > 0) ...[
                          const Icon(Icons.star, size: 17, color: _gold),
                          const SizedBox(width: 4),
                          Text('${listing.rating.toStringAsFixed(1)} (${listing.reviewCount} reviews)'),
                        ] else
                          const Text('New local find'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '\$${listing.currentPrice.toStringAsFixed(0)}',
                style: const TextStyle(color: _navy, fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (listing.city.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.location_on_outlined, size: 16),
                  label: Text(listing.city),
                  backgroundColor: Colors.white,
                ),
              if (listing.pickupAvailable)
                const Chip(
                  avatar: Icon(Icons.storefront_outlined, size: 16),
                  label: Text('Local pickup'),
                  backgroundColor: Colors.white,
                ),
              if (listing.deliveryAvailable)
                const Chip(
                  avatar: Icon(Icons.local_shipping_outlined, size: 16),
                  label: Text('Delivery available'),
                  backgroundColor: Colors.white,
                ),
              if (listing.hasActiveDeal)
                Chip(
                  avatar: const Icon(Icons.local_offer_outlined, size: 16),
                  label: Text('${listing.discountPercent}% off'),
                  backgroundColor: const Color(0xFFF3E1C3),
                ),
            ],
          ),
          const SizedBox(height: 22),
          _card(
            title: 'About this product',
            child: Text(
              listing.description,
              style: const TextStyle(color: _navy, height: 1.55),
            ),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'Local shopping details',
            child: Column(
              children: [
                _detailRow(Icons.location_on_outlined, listing.city.isEmpty ? 'Nearby' : listing.city),
                if (listing.pickupAvailable) _detailRow(Icons.storefront_outlined, 'Available for pickup today'),
                if (listing.deliveryAvailable) _detailRow(Icons.local_shipping_outlined, 'Local delivery available'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ReviewsPreview(
            title: 'Reviews',
            reviews: ReviewService().getListingReviews(listing.listingId),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.push('/place-order', extra: listing),
                  child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/messages'),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Message Seller'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _navy, fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _navy),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: _navy))),
        ],
      ),
    );
  }
}
