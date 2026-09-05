import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/listing_model.dart';
import '../../../models/order_model.dart';
import '../services/order_service.dart';

class PlaceOrderScreen extends StatefulWidget {
  final ListingModel listing;

  const PlaceOrderScreen({
    super.key,
    required this.listing,
  });

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  int quantity = 1;
  bool isSubmitting = false;
  String? fulfillmentMethod;

  @override
  void initState() {
    super.initState();

    if (widget.listing.deliveryAvailable) {
      fulfillmentMethod = 'delivery';
    } else if (widget.listing.pickupAvailable) {
      fulfillmentMethod = 'pickup';
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.listing.price * quantity;
    final canOrder = fulfillmentMethod != null && !isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Order'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.listing.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${widget.listing.price.toStringAsFixed(2)} each',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: quantity > 1
                        ? () {
                            setState(() {
                              quantity--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () {
                      setState(() {
                        quantity++;
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Fulfillment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (!widget.listing.deliveryAvailable &&
                  !widget.listing.pickupAvailable)
                const Text(
                  'This listing does not currently have a delivery or pickup option.',
                  style: TextStyle(color: Colors.redAccent),
                ),
              if (widget.listing.deliveryAvailable)
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'delivery',
                  groupValue: fulfillmentMethod,
                  title: const Text('Delivery'),
                  secondary: const Icon(Icons.local_shipping_outlined),
                  onChanged: (value) {
                    setState(() {
                      fulfillmentMethod = value;
                    });
                  },
                ),
              if (widget.listing.pickupAvailable)
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'pickup',
                  groupValue: fulfillmentMethod,
                  title: const Text('Pickup'),
                  secondary: const Icon(Icons.storefront_outlined),
                  onChanged: (value) {
                    setState(() {
                      fulfillmentMethod = value;
                    });
                  },
                ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Total',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: canOrder ? createOrder : null,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> createOrder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before placing an order.'),
        ),
      );
      return;
    }

    if (fulfillmentMethod == null) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final order = OrderModel(
        orderId: const Uuid().v4(),
        buyerId: user.uid,
        sellerId: widget.listing.sellerId,
        brandId: widget.listing.brandId,
        listingId: widget.listing.listingId,
        productTitle: widget.listing.title,
        unitPrice: widget.listing.price,
        amount: widget.listing.price * quantity,
        quantity: quantity,
        fulfillmentMethod: fulfillmentMethod!,
        status: 'pending',
        createdAt: Timestamp.now(),
      );

      await OrderService().createOrder(order);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order created successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create order: $e'),
        ),
      );
    }
  }
}
