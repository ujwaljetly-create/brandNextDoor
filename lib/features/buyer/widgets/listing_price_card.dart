import 'package:flutter/material.dart';

class ListingPriceCard extends StatelessWidget {
  final double price;

  final String category;

  final String status;

  const ListingPriceCard({
    super.key,
    required this.price,
    required this.category,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable =
        status.toLowerCase() == 'active';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            const Text(
              'Price',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              '\$${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight:
                    FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Row(
              children: [

                const Icon(
                  Icons.category,
                  size: 20,
                  color: Colors.blue,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    category,
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            Row(
              children: [

                Icon(
                  isAvailable
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: isAvailable
                      ? Colors.green
                      : Colors.red,
                ),

                const SizedBox(
                  width: 8,
                ),

                Text(
                  isAvailable
                      ? 'Available'
                      : 'Unavailable',
                  style: TextStyle(
                    color: isAvailable
                        ? Colors.green
                        : Colors.red,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.blue.withOpacity(
                  0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                children: [

                  const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      isAvailable
                          ? 'This item is currently available for purchase.'
                          : 'This item is currently unavailable.',
                      style:
                          const TextStyle(
                        fontSize: 14,
                      ),
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
}