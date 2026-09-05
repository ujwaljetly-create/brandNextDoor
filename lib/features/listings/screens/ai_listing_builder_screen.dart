import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/generated_listing_model.dart';
import '../services/ai_listing_service.dart';

class AIListingBuilderScreen
    extends StatefulWidget {
  const AIListingBuilderScreen({
    super.key,
  });

  @override
  State<AIListingBuilderScreen>
      createState() =>
          _AIListingBuilderScreenState();
}

class _AIListingBuilderScreenState
    extends State<AIListingBuilderScreen> {
  final descriptionController =
      TextEditingController();

  bool isGenerating = false;

  Future<void> generateListing() async {
    if (descriptionController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Tell us about your product.',
          ),
        ),
      );

      return;
    }

    try {
      setState(() {
        isGenerating = true;
      });

      final GeneratedListingModel
          listing =
          await AIListingService()
              .generateListing(
        descriptionController.text
            .trim(),
      );

      if (!mounted) return;

      context.push(
        '/ai-listing-result',
        extra: listing,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Listing Builder',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Tell us about your product',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Colors.white,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                'AI will generate a complete listing including title, description, keywords and pricing.',
                style: TextStyle(
                  color:
                      Colors.white70,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              TextField(
                controller:
                    descriptionController,
                maxLines: 8,
                style: const TextStyle(
                  color: Colors.white,
                ),
                cursorColor: Colors.white,
                decoration:
                    InputDecoration(
                  hintText:
                      'Example:\nHandmade soy candle with lavender scent and eco-friendly packaging.',
                  hintStyle: const TextStyle(
                    color: Colors.white70,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 55,
                child:
                    ElevatedButton(
                  onPressed:
                      isGenerating
                          ? null
                          : generateListing,
                  child:
                      isGenerating
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Generate Listing',
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}