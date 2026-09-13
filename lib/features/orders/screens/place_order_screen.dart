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

  const PlaceOrderScreen({super.key, required this.listing});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  static const _navy = Color(0xFF0C2430);
  static const _gold = Color(0xFFC99245);
  static const _cream = Color(0xFFF8F3EA);

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
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        title: const Text(
          'Place Order',
          style: TextStyle(
            color: _navy,
            fontFamily: 'serif',
            fontWeight: FontWeight.w700,
          ),
        ),
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
                    color: Colors.white,
                    child: const Icon(Icons.broken_image_outlined, size: 56),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              widget.listing.title,
              style: const TextStyle(
                color: _navy,
                fontFamily: 'serif',
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '\$${unitPrice.toStringAsFixed(2)} each',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.listing.hasActiveDeal) ...[
                  Text(
                    '\$${widget.listing.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  Chip(
                    backgroundColor: const Color(0xFFF1E2C9),
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
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.outlined(
                  style: IconButton.styleFrom(
                    foregroundColor: _gold,
                    side: const BorderSide(color: _gold),
                  ),
                  onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    quantity.toString(),
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => setState(() => quantity++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Fulfillment',
              style: TextStyle(
                color: _navy,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (!widget.listing.deliveryAvailable && !widget.listing.pickupAvailable)
              const Text('This listing does not currently have a delivery or pickup option.'),
            if (widget.listing.deliveryAvailable)
              _fulfillmentTile(
                value: 'delivery',
                label: 'Delivery',
                icon: Icons.local_shipping_outlined,
              ),
            if (widget.listing.pickupAvailable)
              _fulfillmentTile(
                value: 'pickup',
                label: 'Pickup',
                icon: Icons.storefront_outlined,
              ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7DED2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Order Total',
                    style: TextStyle(color: _navy, fontSize: 18),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _gold.withValues(alpha: .35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: canOrder ? createOrder : null,
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm Order',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fulfillmentTile({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected = fulfillmentMethod == value;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF3E6D2) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? _gold : const Color(0xFFE7DED2)),
      ),
      child: RadioListTile<String>(
        activeColor: _gold,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        value: value,
        groupValue: fulfillmentMethod,
        title: Text(
          label,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w600),
        ),
        secondary: Icon(icon, color: selected ? _gold : _navy),
        onChanged: (next) => setState(() => fulfillmentMethod = next),
      ),
    );
  }

  Future<void> createOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before placing an order.')),
      );
      return;
    }
    if (fulfillmentMethod == null) return;

    setState(() => isSubmitting = true);

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
        const SnackBar(content: Text('Order created successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create order: $e')),
      );
    }
  }
}
