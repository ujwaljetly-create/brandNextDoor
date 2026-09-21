import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/order_model.dart';
import '../../../models/review_model.dart';
import '../../../services/user_service.dart';
import '../services/review_service.dart';

class ReviewOrderScreen extends StatefulWidget {
  final OrderModel order;

  const ReviewOrderScreen({
    super.key,
    required this.order,
  });

  @override
  State<ReviewOrderScreen> createState() => _ReviewOrderScreenState();
}

class _ReviewOrderScreenState extends State<ReviewOrderScreen> {
  final TextEditingController _commentController = TextEditingController();

  int itemRating = 5;
  int sellerRating = 5;
  bool isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || isSubmitting) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final appUser = await UserService().getUser(user.uid);
      final review = ReviewModel(
        reviewId: widget.order.orderId,
        orderId: widget.order.orderId,
        buyerId: user.uid,
        buyerName: appUser?.name ?? user.displayName ?? 'Buyer',
        sellerId: widget.order.sellerId,
        brandId: widget.order.brandId,
        listingId: widget.order.listingId,
        productTitle: widget.order.productTitle,
        itemRating: itemRating.toDouble(),
        sellerRating: sellerRating.toDouble(),
        comment: _commentController.text.trim(),
        createdAt: Timestamp.now(),
      );

      await ReviewService().submitReview(review);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your review!')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review your order'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.order.productImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                widget.order.productImageUrl,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 18),
          Text(
            widget.order.productTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _RatingSection(
            title: 'Rate the item',
            subtitle: 'How was the product or service?',
            rating: itemRating,
            onChanged: (value) {
              setState(() {
                itemRating = value;
              });
            },
          ),
          const SizedBox(height: 18),
          _RatingSection(
            title: 'Rate the seller',
            subtitle: widget.order.sellerName.isNotEmpty
                ? 'How was your experience with ${widget.order.sellerName}?'
                : 'How was your experience with this seller?',
            rating: sellerRating,
            onChanged: (value) {
              setState(() {
                sellerRating = value;
              });
            },
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _commentController,
            maxLines: 5,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Share your experience (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : _submit,
              icon: const Icon(Icons.star_outline),
              label: Text(isSubmitting ? 'Submitting...' : 'Submit Review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final int rating;
  final ValueChanged<int> onChanged;

  const _RatingSection({
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 12),
            Wrap(
              spacing: 2,
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  tooltip: '$value stars',
                  onPressed: () => onChanged(value),
                  icon: Icon(
                    value <= rating ? Icons.star : Icons.star_border,
                    color: Colors.amber.shade700,
                    size: 32,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
