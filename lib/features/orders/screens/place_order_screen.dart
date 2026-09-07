import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/listing_model.dart';
import '../../../models/order_model.dart';
import '../../../services/user_service.dart';
import '../../brand/services/brand_service.dart';
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
    final unitPrice = widget.listing.currentPrice;
    final total = unitPrice * quantity;
    final canOrder = fulfillmentMethod != null && !isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Order'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.listing.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  widget.listing.images.first,
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 210,
                    color: Theme.of(context).cardColor,
                    child: const Icon(Icons.broken_image_outlined, size: 56),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              widget.listing.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '\$${unitPrice.toStringAsFixed(2)} each',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (widget.listing.hasActiveDeal) ...[
                  const SizedBox(width: 10),
                  Text(
                    '\$${widget.listing.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          decoration: TextDecoration.lineThrough,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${widget.listing.discountPercent}% off'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
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

    if (fulfillmentMethod == null) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      final appUser = await UserService().getUser(user.uid);
      final brand = widget.listing.brandId.isNotEmpty
          ? await BrandService().getBrand(widget.listing.brandId)
          : null;

      final now = Timestamp.now();
      final unitPrice = widget.listing.currentPrice;
      final order = OrderModel(
        orderId: const Uuid().v4(),
        buyerId: user.uid,
        buyerName: appUser?.name ?? user.displayName ?? 'Buyer',
        sellerId: widget.listing.sellerId,
        sellerName: (brand?['brandName'] ?? 'Seller').toString(),
        sellerLogoUrl: (brand?['logoUrl'] ?? '').toString(),
        brandId: widget.listing.brandId,
        listingId: widget.listing.listingId,
        productTitle: widget.listing.title,
        productImageUrl:
            widget.listing.images.isNotEmpty ? widget.listing.images.first : '',
        productCategory: widget.listing.category,
        unitPrice: unitPrice,
        amount: unitPrice * quantity,
        quantity: quantity,
        fulfillmentMethod: fulfillmentMethod!,
        status: 'pending',
        rejectionReason: '',
        createdAt: now,
        updatedAt: now,
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
