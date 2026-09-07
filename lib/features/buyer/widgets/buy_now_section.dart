import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';

class BuyNowSection extends StatelessWidget {
  final ListingModel listing;

  const BuyNowSection({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 350;

            final price = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Price',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${listing.currentPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            );

            final buyButton = SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Buy Now'),
                onPressed: () {
                  context.push('/place-order', extra: listing);
                },
              ),
            );

            final chatButton = SizedBox(
              height: 52,
              width: 52,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat feature coming soon.'),
                    ),
                  );
                },
                child: const Icon(Icons.chat_bubble_outline),
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  price,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: buyButton),
                      const SizedBox(width: 10),
                      chatButton,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: price),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: buyButton),
                const SizedBox(width: 12),
                chatButton,
              ],
            );
          },
        ),
      ),
    );
  }
}
