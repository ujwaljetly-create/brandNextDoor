import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/listing_model.dart';
import '../services/saved_items_service.dart';
import '../widgets/product_card.dart';

class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  static const _navy = Color(0xFF0C2430);
  static const _cream = Color(0xFFF8F3EA);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        title: const Text(
          'Saved Items',
          style: TextStyle(
            color: _navy,
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Please sign in to view saved items.'))
          : StreamBuilder<List<ListingModel>>(
              stream: SavedItemsService().watchSavedItems(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? const <ListingModel>[];
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_border, size: 52, color: _navy),
                          const SizedBox(height: 14),
                          const Text(
                            'No saved items yet',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the heart on any product to save it here.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: () => context.go('/marketplace'),
                            child: const Text('Explore Products'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: .70,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) => ProductCard(listing: items[index]),
                );
              },
            ),
    );
  }
}
