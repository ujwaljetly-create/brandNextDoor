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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min,
                children: [

                  const Text(
                    'Price',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    '\$${listing.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              flex: 2,
              child: SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.shopping_cart,
                  ),
                  label: const Text(
                    'Buy Now',
                  ),
                  onPressed: () {
                    context.push(
                      '/place-order',
                      extra: listing,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            SizedBox(
              height: 55,
              width: 55,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Chat feature coming soon.',
                      ),
                    ),
                  );
                },
                child: const Icon(
                  Icons.chat_bubble_outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}