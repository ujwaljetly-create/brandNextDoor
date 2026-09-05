import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../services/listing_service.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sellerId =
        FirebaseAuth
            .instance
            .currentUser!
            .uid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
          ),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text(
          'My Listings',
        ),
      ),
      body: StreamBuilder<
          List<ListingModel>>(
        stream: ListingService()
            .getSellerListings(
          sellerId,
        ),
        builder:
            (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error
                    .toString(),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No Listings Found',
              ),
            );
          }

          final listings =
              snapshot.data!;

          return ListView.builder(
            padding:
                const EdgeInsets.only(
              top: 12,
              bottom: 24,
            ),
            itemCount:
                listings.length,
            itemBuilder:
                (context, index) {
              final listing =
                  listings[index];

              return Card(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.all(
                    12,
                  ),

                  leading:
                      listing.images
                              .isNotEmpty
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                              child:
                                  Image.network(
                                listing
                                    .images
                                    .first,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: Icon(
                                      Icons.image,
                                    ),
                                  );
                                },
                              ),
                            )
                          : const SizedBox(
                              width: 60,
                              height: 60,
                              child: Icon(
                                Icons.image,
                                size: 40,
                              ),
                            ),

                  title: Text(
                    listing.title,
                    maxLines: 1,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight
                              .w600,
                    ),
                  ),

                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 6,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          listing.category,
                        ),

                        Text(
                          listing.status,
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          '\$${listing.price.toStringAsFixed(2)}',
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight
                                    .bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  trailing:
                      PopupMenuButton<String>(
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit Listing',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete Listing',
                        ),
                      ),
                    ],

                    onSelected:
                        (value) async {
                      if (value ==
                          'edit') {
                        await context.push(
                          '/edit-listing',
                          extra: listing,
                        );
                      }

                      if (value ==
                          'delete') {
                        final confirm =
                            await showDialog<bool>(
                          context: context,
                          builder:
                              (_) =>
                                  AlertDialog(
                            title:
                                const Text(
                              'Delete Listing',
                            ),
                            content:
                                const Text(
                              'Are you sure you want to delete this listing?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    false,
                                  );
                                },
                                child:
                                    const Text(
                                  'Cancel',
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    true,
                                  );
                                },
                                child:
                                    const Text(
                                  'Delete',
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm ==
                            true) {
                          await ListingService()
                              .deleteListing(
                            listing
                                .listingId,
                          );

                          if (context
                              .mounted) {
                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Listing Deleted',
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}