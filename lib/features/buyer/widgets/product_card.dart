import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';

class ProductCard extends StatelessWidget {
  final ListingModel listing;

  const ProductCard({super.key, required this.listing});

  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/listing-details', extra: listing),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9E1D5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      child: listing.images.isNotEmpty
                          ? Image.network(
                              listing.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_border, size: 19, color: _navy),
                      ),
                    ),
                    if (listing.hasActiveDeal)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            '${listing.discountPercent}% OFF',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (listing.city.isNotEmpty)
                      Text(
                        listing.city.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF7E898F), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: .8),
                      ),
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _navy, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          '\$${listing.currentPrice.toStringAsFixed(0)}',
                          style: const TextStyle(color: _navy, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        if (listing.hasActiveDeal) ...[
                          const SizedBox(width: 6),
                          Text(
                            '\$${listing.price.toStringAsFixed(0)}',
                            style: const TextStyle(color: Colors.grey, fontSize: 11, decoration: TextDecoration.lineThrough),
                          ),
                        ],
                        const Spacer(),
                        if (listing.rating > 0) ...[
                          const Icon(Icons.star, size: 13, color: _gold),
                          const SizedBox(width: 2),
                          Text(listing.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFFF1ECE4),
        child: const Center(child: Icon(Icons.image_outlined, color: _navy, size: 38)),
      );
}
