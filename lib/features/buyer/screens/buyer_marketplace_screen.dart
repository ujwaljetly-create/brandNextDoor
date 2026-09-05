import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../../listings/services/listing_service.dart';

class BuyerMarketplaceScreen
    extends StatefulWidget {
  const BuyerMarketplaceScreen({
    super.key,
  });

  @override
  State<BuyerMarketplaceScreen>
      createState() =>
          _BuyerMarketplaceScreenState();
}

class _BuyerMarketplaceScreenState
    extends State<
        BuyerMarketplaceScreen> {
  final searchController =
      TextEditingController();

  String searchText = '';

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Marketplace',
        ),
      ),
      body: Column(
        children: [

          Padding(
            padding:
                const EdgeInsets.all(
              16,
            ),
            child: TextField(
              controller:
                  searchController,
              onChanged: (value) {
                setState(() {
                  searchText =
                      value
                          .toLowerCase();
                });
              },
              decoration:
                  InputDecoration(
                hintText:
                    'Search products...',
                prefixIcon:
                    const Icon(
                  Icons.search,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<
                List<ListingModel>>(
              stream:
                  ListingService()
                      .getMarketplaceListings(),
              builder:
                  (
                context,
                snapshot,
              ) {
                if (snapshot
                        .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (!snapshot
                        .hasData ||
                    snapshot
                        .data!
                        .isEmpty) {
                  return const Center(
                    child: Text(
                      'No Listings Available',
                    ),
                  );
                }

                final listings =
                    snapshot.data!
                        .where(
                  (
                    listing,
                  ) {
                    return listing
                        .title
                        .toLowerCase()
                        .contains(
                          searchText,
                        );
                  },
                ).toList();

                if (listings
                    .isEmpty) {
                  return const Center(
                    child: Text(
                      'No Results Found',
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.only(
                    bottom: 24,
                  ),
                  itemCount:
                      listings.length,
                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final listing =
                        listings[index];

                    return Card(
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal:
                            16,
                        vertical: 8,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                      child:
                          InkWell(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                        onTap: () {
                          context.push(
                            '/listing-details',
                            extra:
                                listing,
                          );
                        },
                        child:
                            Padding(
                          padding:
                              const EdgeInsets.all(
                            12,
                          ),
                          child:
                              Row(
                            children: [

                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                  12,
                                ),
                                child:
                                    listing.images.isNotEmpty
                                        ? Image.network(
                                            listing.images.first,
                                            width:
                                                90,
                                            height:
                                                90,
                                            fit:
                                                BoxFit.cover,
                                          )
                                        : Container(
                                            width:
                                                90,
                                            height:
                                                90,
                                            color:
                                                Colors.grey.shade300,
                                            child:
                                                const Icon(
                                              Icons.image,
                                            ),
                                          ),
                              ),

                              const SizedBox(
                                width:
                                    12,
                              ),

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [

                                    Text(
                                      listing.title,
                                      maxLines:
                                          2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            16,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height:
                                          6,
                                    ),

                                    Text(
                                      listing.category,
                                      style:
                                          const TextStyle(
                                        color:
                                            Colors.grey,
                                      ),
                                    ),

                                    const SizedBox(
                                      height:
                                          6,
                                    ),

                                    Text(
                                      '\$${listing.price.toStringAsFixed(2)}',
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            18,
                                        fontWeight:
                                            FontWeight.bold,
                                        color:
                                            Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}