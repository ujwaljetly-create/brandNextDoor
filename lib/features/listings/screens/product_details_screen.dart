import 'package:flutter/material.dart';

import '../../../models/listing_model.dart';
import '../../chat/screens/chat_screen.dart';
import '../../orders/screens/place_order_screen.dart';
import '../widgets/chat_seller_button.dart';
import '../widgets/image_carousel.dart';
import '../widgets/place_order_button.dart';
import '../widgets/seller_info_card.dart';

class ProductDetailsScreen
    extends StatelessWidget {
  final ListingModel listing;

  const ProductDetailsScreen({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ImageCarousel(
              images: listing.images,
            ),

            Padding(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    listing.title,
                    style:
                        const TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    '\$${listing.price}',
                    style:
                        const TextStyle(
                      fontSize: 24,
                      color: Colors.green,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  SellerInfoCard(
                    sellerName:
                        'John Smith',
                    brandName:
                        'GlowCraft',
                    trustScore: 4.8,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Description',
                    style:
                        TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    listing.description,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  if (listing
                      .deliveryAvailable)
                    const ListTile(
                      leading: Icon(
                        Icons.local_shipping,
                      ),
                      title: Text(
                        'Delivery Available',
                      ),
                    ),

                  if (listing
                      .pickupAvailable)
                    const ListTile(
                      leading:
                          Icon(Icons.store),
                      title: Text(
                        'Pickup Available',
                      ),
                    ),

                  const SizedBox(
                    height: 30,
                  ),

                  Row(
                    children: [
                      ChatSellerButton(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ChatScreen(
          chatId:
              'sampleChatId',
        ),
      ),
    );
  },
),

                      const SizedBox(
                        width: 12,
                      ),

                      PlaceOrderButton(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PlaceOrderScreen(
          listing: listing,
        ),
      ),
    );
  },
)
                    ],
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