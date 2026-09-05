import 'package:flutter/material.dart';

class DeliveryInfoCard extends StatelessWidget {
  final bool deliveryAvailable;
  final bool pickupAvailable;
  final String? city;

  const DeliveryInfoCard({
    super.key,
    required this.deliveryAvailable,
    required this.pickupAvailable,
    this.city,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            const Text(
              'Delivery Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Row(
              children: [

                Icon(
                  deliveryAvailable
                      ? Icons.check_circle
                      : Icons.cancel,
                  color:
                      deliveryAvailable
                          ? Colors.green
                          : Colors.red,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Text(
                    deliveryAvailable
                        ? 'Delivery Available'
                        : 'Delivery Not Available',
                    style:
                        const TextStyle(
                      fontSize: 16,
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
                  pickupAvailable
                      ? Icons.store
                      : Icons.store_mall_directory_outlined,
                  color:
                      pickupAvailable
                          ? Colors.blue
                          : Colors.grey,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Text(
                    pickupAvailable
                        ? 'Pickup Available'
                        : 'Pickup Not Available',
                    style:
                        const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            if (city != null &&
                city!.isNotEmpty) ...[
              const SizedBox(
                height: 20,
              ),

              const Divider(),

              const SizedBox(
                height: 10,
              ),

              Row(
                children: [

                  const Icon(
                    Icons.location_on,
                    color: Colors.orange,
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Text(
                      city!,
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
            ],

            const SizedBox(
              height: 24,
            ),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(
                14,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.green
                    .withOpacity(
                  0.08,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Icon(
                    Icons.local_shipping,
                    color: Colors.green,
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      deliveryAvailable
                          ? 'Estimated delivery time is typically between 30–45 minutes depending on your location.'
                          : 'Please contact the seller regarding pickup arrangements.',
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