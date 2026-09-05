import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ai_brand_builder/models/generated_brand_model.dart';
import '../services/brand_service.dart';

class SellerBrandScreen extends StatefulWidget {
  const SellerBrandScreen({
    super.key,
  });

  @override
  State<SellerBrandScreen> createState() =>
      _SellerBrandScreenState();
}

class _SellerBrandScreenState
    extends State<SellerBrandScreen> {
  bool isLoading = true;

  Map<String, dynamic>? brand;

  @override
  void initState() {
    super.initState();
    loadBrand();
  }

  Future<void> loadBrand() async {
    try {
      final result =
          await BrandService()
              .getSellerBrand();

      if (!mounted) return;

      setState(() {
        brand = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(
      BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (brand == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
            ),
            onPressed: () {
              context.pop();
            },
          ),
          title: const Text(
            'My Brand',
          ),
        ),
        body: const Center(
          child: Text(
            'No Brand Found',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
          ),
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text(
          'My Brand',
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            /// Logo
            if ((brand!['logoUrl'] ?? '')
                .toString()
                .isNotEmpty)
              Center(
                child: Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 24,
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius
                            .circular(
                      24,
                    ),
                    child:
                        Image.network(
                      brand!['logoUrl'],
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

            /// Brand Name
            Text(
              brand!['brandName'] ?? '',
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 32,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            /// Tagline
            Text(
              brand!['tagline'] ?? '',
              style:
                  const TextStyle(
                color:
                    Colors.white70,
                fontSize: 18,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            /// Description
            const Text(
              'Description',
              style: TextStyle(
                color:
                    Colors.white,
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              brand!['description'] ?? '',
              style:
                  const TextStyle(
                color:
                    Colors.white,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            /// Brand Colors
            const Text(
              'Brand Colors',
              style: TextStyle(
                color:
                    Colors.white,
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Wrap(
              spacing: 8,
              children:
                  ((brand!['colors']
                              as List?) ??
                          [])
                      .map(
                        (e) => Chip(
                          label: Text(
                            e.toString(),
                          ),
                        ),
                      )
                      .toList(),
            ),

            const SizedBox(
              height: 30,
            ),

            /// Personality
            const Text(
              'Personality',
              style: TextStyle(
                color:
                    Colors.white,
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Wrap(
              spacing: 8,
              children:
                  ((brand![
                                  'personalityTraits']
                              as List?) ??
                          [])
                      .map(
                        (e) => Chip(
                          label: Text(
                            e.toString(),
                          ),
                        ),
                      )
                      .toList(),
            ),

            const SizedBox(
              height: 40,
            ),

            /// Create Listing
            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  context.go(
                    '/create-listing',
                  );
                },
                icon: const Icon(
                  Icons.add,
                ),
                label: const Text(
                  'Create Listing',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            /// Edit Brand
            SizedBox(
              width:
                  double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    () async {
                  final result =
                      await context
                          .push(
                    '/edit-brand',
                    extra: brand,
                  );

                  if (result ==
                      true) {
                    loadBrand();
                  }
                },
                icon: const Icon(
                  Icons.edit,
                ),
                label: const Text(
                  'Edit Brand',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            /// Generate AI Logo
            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed: () {

                  final generatedBrand =
                      GeneratedBrandModel(
                    brandId:
                        brand![
                                'brandId'] ??
                            '',
                    brandName:
                        brand![
                                'brandName'] ??
                            '',
                    tagline:
                        brand![
                                'tagline'] ??
                            '',
                    description:
                        brand![
                                'description'] ??
                            '',
                    colors:
                        List<String>.from(
                      brand![
                              'colors'] ??
                          [],
                    ),
                    personalityTraits:
                        List<String>.from(
                      brand![
                              'personalityTraits'] ??
                          [],
                    ),
                    targetAudience:
                        List<String>.from(
                      brand![
                              'targetAudience'] ??
                          [],
                    ),
                    brandScore:
                        brand![
                                'brandScore'] ??
                            90,
                  );

                  context.push(
                    '/ai-logo-generation',
                    extra:
                        generatedBrand,
                  );
                },
                icon: const Icon(
                  Icons.auto_awesome,
                ),
                label: const Text(
                  'Generate AI Logo',
                ),
              ),
            ),

            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}