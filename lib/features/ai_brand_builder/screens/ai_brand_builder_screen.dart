import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/ai_brand_service.dart';

class AIBrandBuilderScreen
    extends StatefulWidget {
  const AIBrandBuilderScreen({
    super.key,
  });

  @override
  State<AIBrandBuilderScreen>
      createState() =>
          _AIBrandBuilderScreenState();
}

class _AIBrandBuilderScreenState
    extends State<AIBrandBuilderScreen> {
  final businessController =
      TextEditingController();

  bool isLoading = false;

  Future<void> generateBrand() async {
    try {
      setState(() {
        isLoading = true;
      });

      final result =
          await AIBrandService()
              .generateBrand(
        businessInfo:
            businessController.text,
      );

      if (!mounted) return;

      context.push(
  '/ai-brand-studio',
  extra: result,
);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Brand Builder',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              
              'Tell us about your business',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            TextField(
              controller:
                  businessController,
              maxLines: 8,
              decoration:
                  const InputDecoration(
                hintText:
                    'Example:\n\nI make handmade soy candles.\nMy customers are homeowners.\nMy products are eco-friendly.',
                border:
                    OutlineInputBorder(),
              ),
              style: TextStyle(
  color: Colors.white.withOpacity(0.9),
)
            ),

            const SizedBox(
              height: 30,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : generateBrand,
                child:
                    isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Generate Brand',
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}