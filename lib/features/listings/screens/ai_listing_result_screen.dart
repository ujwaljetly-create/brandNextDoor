import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/generated_listing_model.dart';

class AIListingResultScreen
    extends StatelessWidget {
  final GeneratedListingModel
      listing;

  const AIListingResultScreen({
    super.key,
    required this.listing,
  });

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Listing',
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              listing.title,
              style:
                  const TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.white,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.white,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              listing.description,
              style:
                  const TextStyle(
                color:
                    Colors.white,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Benefits',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.white,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              listing.benefits,
              style:
                  const TextStyle(
                color:
                    Colors.white,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Keywords',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.white,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Wrap(
              spacing: 8,
              children: listing
                  .keywords
                  .map(
                    (e) => Chip(
                      label:
                          Text(e),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(
              height: 24,
            ),

            Text(
              'Suggested Price: \$${listing.suggestedPrice}',
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.white,
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed: () {
                  context.push(
                    '/create-listing',
                    extra: listing,
                  );
                },
                child: const Text(
                  'Use This Listing',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}