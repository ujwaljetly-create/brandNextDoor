import 'package:flutter/material.dart';

class PlaceOrderButton
    extends StatelessWidget {
  final VoidCallback onTap;

  const PlaceOrderButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.shopping_cart,
        ),
        label: const Text(
          'Place Order',
        ),
      ),
    );
  }
}