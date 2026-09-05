import 'package:flutter/material.dart';

class RecentOrderCard extends StatelessWidget {
  final String customerName;
  final String itemName;
  final String amount;

  const RecentOrderCard({
    super.key,
    required this.customerName,
    required this.itemName,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(customerName),
        subtitle: Text(itemName),
        trailing: Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}