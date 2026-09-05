import 'package:flutter/material.dart';

class ChatSellerButton
    extends StatelessWidget {
  final VoidCallback onTap;

  const ChatSellerButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.chat),
        label: const Text(
          'Chat Seller',
        ),
      ),
    );
  }
}