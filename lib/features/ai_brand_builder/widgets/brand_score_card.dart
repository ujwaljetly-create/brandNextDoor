import 'package:flutter/material.dart';

class BrandScoreCard extends StatelessWidget {
  final int score;

  const BrandScoreCard({
    super.key,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7B61FF),
            Color(0xFFE14DAD),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Brand Strength Score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '$score / 100',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Recommendations',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            '✓ Great Brand Name',
            style: TextStyle(
              color: Colors.white,
            ),
          ),

          const Text(
            '✓ Strong Description',
            style: TextStyle(
              color: Colors.white,
            ),
          ),

          const Text(
            '⚠ Generate Logo',
            style: TextStyle(
              color: Colors.white,
            ),
          ),

          const Text(
            '⚠ Add Listings',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}