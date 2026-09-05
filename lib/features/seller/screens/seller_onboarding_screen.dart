import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SellerOnboardingScreen extends StatelessWidget {
  const SellerOnboardingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Your Brand',
        ),
      ),
      body: SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 20),

        const Text(
          'Build Your Brand',
          style: TextStyle(
            fontSize: 30,
            fontWeight:
                FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Brand Next Door can help you create a professional brand in minutes using AI.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 32),

        // AI CARD

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            gradient:
                const LinearGradient(
              colors: [
                Color(0xFF7B61FF),
                Color(0xFFE14DAD),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 40,
              ),

              const SizedBox(height: 16),

              const Text(
                'Build Brand With AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Generate a brand name, tagline, description, colors and logo concepts using AI.',
                style: TextStyle(
                  color:
                      Colors.white70,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width:
                    double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.go(
                      '/ai-brand-builder',
                    );
                  },
                  child: const Text(
                    'Start With AI',
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // MANUAL CARD

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: Colors.white24,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              const Icon(
                Icons.edit,
                size: 40,
                color: Colors.white,
              ),

              const SizedBox(height: 16),

              const Text(
                'Build Brand Yourself',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Already have a brand? Add your own brand name, logo and description.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width:
                    double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    context.go(
                      '/brand-profile',
                    );
                  },
                  child: const Text(
                    'Create Manually',
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        const Center(
          child: Text(
            'Most sellers choose AI to create their brand in minutes.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    ),
  ),
),
    );
  }
}