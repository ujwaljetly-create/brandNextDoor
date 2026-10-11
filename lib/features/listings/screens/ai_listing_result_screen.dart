import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/generated_listing_model.dart';

class AIListingResultScreen extends StatelessWidget {
  final GeneratedListingModel listing;

  const AIListingResultScreen({super.key, required this.listing});

  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: _navy),
        ),
        title: const Text('Your Listing is Ready!', style: TextStyle(color: _navy, fontFamily: 'serif', fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                children: [
                  const Text('Here’s what we created for you.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF6D777C))),
                  const SizedBox(height: 18),
                  Container(
                    height: 190,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(colors: [Color(0xFFF1DEC0), Color(0xFFE2C79D)]),
                    ),
                    child: const Center(
                      child: Icon(Icons.shopping_bag_outlined, color: _navy, size: 82),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _row('Product Title', listing.title),
                  _row('Suggested Price', '\$${listing.suggestedPrice.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  _card(
                    title: 'Description',
                    child: Text(listing.description, style: const TextStyle(color: _navy, height: 1.5)),
                  ),
                  _card(
                    title: 'Benefits',
                    child: Text(listing.benefits, style: const TextStyle(color: _navy, height: 1.45)),
                  ),
                  _card(
                    title: 'Tags',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: listing.keywords.map((tag) => Chip(label: Text('#$tag'), backgroundColor: const Color(0xFFF1E7D8))).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Edit Prompt'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.white),
                      onPressed: () => context.push('/create-listing', extra: listing),
                      child: const Text('Use Listing', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Color(0xFF68747A), fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: _navy, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DED2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _navy, fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }
}
