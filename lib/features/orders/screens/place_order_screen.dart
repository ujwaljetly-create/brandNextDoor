import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/listing_model.dart';
import '../../../models/order_model.dart';
import '../services/order_service.dart';

class PlaceOrderScreen
    extends StatefulWidget {
  final ListingModel listing;

  const PlaceOrderScreen({
    super.key,
    required this.listing,
  });

  @override
  State<PlaceOrderScreen>
      createState() =>
          _PlaceOrderScreenState();
}

class _PlaceOrderScreenState
    extends State<PlaceOrderScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final total =
        widget.listing.price *
            quantity;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Place Order'),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              widget.listing.title,
              style:
                  const TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
                height: 20),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                IconButton(
                  onPressed: () {
                    if (quantity >
                        1) {
                      setState(() {
                        quantity--;
                      });
                    }
                  },
                  icon: const Icon(
                    Icons.remove,
                  ),
                ),
                Text(
                  quantity.toString(),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      quantity++;
                    });
                  },
                  icon: const Icon(
                    Icons.add,
                  ),
                ),
              ],
            ),

            const SizedBox(
                height: 20),

            Text(
              'Total: \$${total.toStringAsFixed(2)}',
            ),

            const Spacer(),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed:
                    createOrder,
                child:
                    const Text(
                  'Confirm Order',
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void>
      createOrder() async {
    final order = OrderModel(
      orderId:
          const Uuid().v4(),

      buyerId:
          'demoBuyerId',

      sellerId:
          widget.listing.sellerId,

      listingId:
          widget.listing.listingId,

      productTitle:
          widget.listing.title,

      amount:
          widget.listing.price *
              quantity,

      quantity:
          quantity,

      status:
          'pending',

      createdAt:
          Timestamp.now(),
    );

    await OrderService()
        .createOrder(order);

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content:
            Text('Order Created'),
      ),
    );
  }
}