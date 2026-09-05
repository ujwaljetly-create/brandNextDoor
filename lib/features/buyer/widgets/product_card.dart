import 'package:flutter/material.dart';

import '../../../models/listing_model.dart';
import '../../listings/screens/product_details_screen.dart';

class ProductCard
    extends StatelessWidget {
  final ListingModel listing;

  const ProductCard({
    super.key,
    required this.listing,
  });

  @override
  Widget build(
      BuildContext context) {
    return InkWell(
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProductDetailsScreen(
        listing: listing,
      ),
    ),
  );
},
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(20),
          color: const Color(
            0xff1A1A1A,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius
                        .vertical(
                  top: Radius.circular(
                    20,
                  ),
                ),
                child: Image.network(
                  listing.images.first,
                  fit: BoxFit.cover,
                  width:
                      double.infinity,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.all(
                12,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    '\$${listing.price}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}