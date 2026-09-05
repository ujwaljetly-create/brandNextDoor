import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../models/generated_brand_model.dart';

class BrandGenerationResultScreen
    extends StatelessWidget {
  final GeneratedBrandModel brand;

  const BrandGenerationResultScreen({
    super.key,
    required this.brand,
  });

  Future<void> saveBrand(
      BuildContext context) async {
    final user =
        FirebaseAuth
            .instance
            .currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('brands')
        .doc(
          const Uuid().v4(),
        )
        .set({
      'sellerId': user.uid,
      'brandName':
          brand.brandName,
      'tagline':
          brand.tagline,
      'description':
          brand.description,
      'colors': brand.colors,
      'personalityTraits':
          brand.personalityTraits,
      'aiGenerated': true,
      'createdAt':
          Timestamp.now(),
    });

    if (context.mounted) {
      context.go(
        '/seller-dashboard',
      );
    }
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Brand',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                brand.brandName,
                style:
                    TextStyle(
                  fontSize: 32,
                  fontWeight:
                      FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                brand.tagline,
                style:
                    const TextStyle(
                  fontSize: 18,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              Text(
                brand.description,
                style:
                    TextStyle(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              const Text(
                'Brand Colors',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Wrap(
                spacing: 8,
                children: brand.colors
                    .map(
                      (e) => Chip(
                        label:
                            Text(e),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(
                height: 30,
              ),

              const Text(
                'Personality',
                style: TextStyle(
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Wrap(
                spacing: 8,
                children: brand
                    .personalityTraits
                    .map(
                      (e) => Chip(
                        label:
                            Text(e,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                            ),
                            ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(
                height: 40,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    ElevatedButton(
  onPressed: () {
    context.push(
      '/ai-logo-generation',
      extra: brand,
    );
  },
  child: const Text(
    'Generate Logo Concepts',
  ),
)
              ),
            ],
          ),
        ),
      ),
    );
  }
}