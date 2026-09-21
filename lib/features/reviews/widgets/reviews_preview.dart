import 'package:flutter/material.dart';

import '../../../models/review_model.dart';

class ReviewsPreview extends StatelessWidget {
  final String title;
  final Stream<List<ReviewModel>> reviews;
  final bool sellerRating;

  const ReviewsPreview({
    super.key,
    required this.title,
    required this.reviews,
    this.sellerRating = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: reviews,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <ReviewModel>[];

        if (snapshot.connectionState == ConnectionState.waiting &&
            items.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (items.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.star_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('No $title yet. Be the first to leave one.'),
                  ),
                ],
              ),
            ),
          );
        }

        final total = items.fold<double>(
          0,
          (sum, review) =>
              sum + (sellerRating ? review.sellerRating : review.itemRating),
        );
        final average = total / items.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      average.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text('(${items.length})'),
                  ],
                ),
                const SizedBox(height: 14),
                ...items.take(3).map((review) {
                  final rating =
                      sellerRating ? review.sellerRating : review.itemRating;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                review.buyerName.isNotEmpty
                                    ? review.buyerName
                                    : 'Buyer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 3),
                            Text(rating.toStringAsFixed(1)),
                          ],
                        ),
                        if (review.comment.trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(review.comment.trim()),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
