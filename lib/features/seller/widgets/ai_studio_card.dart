import 'package:flutter/material.dart';

class AIStudioCard extends StatelessWidget {
  const AIStudioCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Colors.deepPurple,
            Colors.purpleAccent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 40,
          ),

          const SizedBox(height: 12),

          const Text(
            'AI Studio',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Generate listings, logos, captions and marketing content.',
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {},
            child: const Text('Open AI Studio'),
          ),
        ],
      ),
    );
  }
}