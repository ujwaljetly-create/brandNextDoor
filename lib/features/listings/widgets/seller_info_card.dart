import 'package:flutter/material.dart';

class SellerInfoCard extends StatelessWidget {
  final String sellerName;
  final String brandName;
  final double trustScore;

  const SellerInfoCard({
    super.key,
    required this.sellerName,
    required this.brandName,
    required this.trustScore,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.store),
        ),
        title: Text(brandName),
        subtitle: Text(
          'Seller: $sellerName',
        ),
        trailing: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified,
              color: Colors.green,
            ),
            Text(
              trustScore.toStringAsFixed(1),
            ),
          ],
        ),
      ),
    );
  }
}