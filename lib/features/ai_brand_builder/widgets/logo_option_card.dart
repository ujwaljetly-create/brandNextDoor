import 'package:flutter/material.dart';

class LogoOptionCard extends StatelessWidget {
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const LogoOptionCard({
    super.key,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? Colors.green
                : Colors.grey.shade300,
            width: selected ? 3 : 1,
          ),
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(16),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}