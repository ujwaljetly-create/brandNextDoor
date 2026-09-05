import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/buyer_home_provider.dart';
import '../widgets/product_card.dart';

class BuyerHomeScreen
    extends ConsumerWidget {
  const BuyerHomeScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final listings =
        ref.watch(
      buyerListingsProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Brand Next Door',
        ),
      ),
      body: listings.when(
        data: (items) {
          return ListView(
            padding:
                const EdgeInsets.all(
              20,
            ),
            children: [
              const Text(
                'Discover Local Brands',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount:
                    items.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      2,
                  childAspectRatio:
                      .72,
                  crossAxisSpacing:
                      12,
                  mainAxisSpacing:
                      12,
                ),
                itemBuilder:
                    (
                  context,
                  index,
                ) {
                  return ProductCard(
                    listing:
                        items[index],
                  );
                },
              ),
            ],
          );
        },
        loading: () =>
            const Center(
          child:
              CircularProgressIndicator(),
        ),
        error:
            (e, stack) =>
                Center(
          child:
              Text(e.toString()),
        ),
      ),
    );
  }
}