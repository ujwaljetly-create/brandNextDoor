import 'package:flutter/material.dart';

import '../../../models/listing_model.dart';
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
        title: const Text(
          'Listing Details',
        ),
      ),

      bottomNavigationBar: BuyNowSection(
        listing: listing,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            /// Images
            ListingImageSection(
              images: listing.images,
            ),

            const SizedBox(
              height: 24,
            ),

            /// Title
            Text(
              listing.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            /// Category Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                listing.category,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            /// Brand
            BrandInfoCard(
              brandId:
                  listing.brandId,
            ),

            const SizedBox(
              height: 24,
            ),

            /// Price
            ListingPriceCard(
              price:
                  listing.price,
              category:
                  listing.category,
              status:
                  listing.status,
            ),

            const SizedBox(
              height: 24,
            ),

            /// Description
            Card(
              elevation: 2,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  18,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Text(
                      listing.description,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            /// Delivery Information
            DeliveryInfoCard(
              deliveryAvailable:
                  listing
                      .deliveryAvailable,
              pickupAvailable:
                  listing
                      .pickupAvailable,
            ),

            const SizedBox(
              height: 100,
            ),
          ],
        ),
      ),
    );
  }
}