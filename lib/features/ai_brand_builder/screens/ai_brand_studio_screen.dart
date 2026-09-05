import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ai/openai_service.dart';
import '../../../features/brand/services/brand_service.dart';
import '../models/generated_brand_model.dart';
import '../widgets/brand_score_card.dart';
class AIBrandStudioScreen extends StatefulWidget {
  final GeneratedBrandModel brand;

  const AIBrandStudioScreen({
    super.key,
    required this.brand,
  });

  @override
  State<AIBrandStudioScreen> createState() =>
      _AIBrandStudioScreenState();
}

class _AIBrandStudioScreenState
    extends State<AIBrandStudioScreen> {
  bool isSaving = false;
  late String brandName;
late String tagline;
late String description;

late List<String> colors;
late List<String> audience;
late List<String> personality;

bool isGenerating = false;
@override
void initState() {
  super.initState();

  brandName =
      widget.brand.brandName;

  tagline =
      widget.brand.tagline;

  description =
      widget.brand.description;

  colors =
      widget.brand.colors;

  audience =
      widget.brand.targetAudience;

  personality =
      widget.brand.personalityTraits;
}
Future<void> editBrand() async {
  final brandController =
      TextEditingController(
    text: brandName,
  );

  final taglineController =
      TextEditingController(
    text: tagline,
  );

  final descriptionController =
      TextEditingController(
    text: description,
  );

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        Colors.transparent,
    builder: (context) {
      return Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom:
              MediaQuery.of(
                    context,
                  )
                  .viewInsets
                  .bottom +
              24,
        ),
        decoration: const BoxDecoration(
          color: Color(
            0xFF1A1A1A,
          ),
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(
              30,
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Row(
                children: [

                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  const Text(
                    'Edit Brand',
                    style: TextStyle(
                      color:
                          Colors.white,
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 24,
              ),

              TextField(
                controller:
                    brandController,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                ),
                decoration:
                    InputDecoration(
                  labelText:
                      'Brand Name',
                  labelStyle:
                      const TextStyle(
                    color:
                        Colors.white70,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              TextField(
                controller:
                    taglineController,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                ),
                decoration:
                    InputDecoration(
                  labelText:
                      'Tagline',
                  labelStyle:
                      const TextStyle(
                    color:
                        Colors.white70,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              TextField(
                controller:
                    descriptionController,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                ),
                maxLines: 5,
                decoration:
                    InputDecoration(
                  labelText:
                      'Description',
                  labelStyle:
                      const TextStyle(
                    color:
                        Colors.white70,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
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
                  onPressed: () {
                    setState(() {
                      brandName =
                          brandController
                              .text
                              .trim();

                      tagline =
                          taglineController
                              .text
                              .trim();

                      description =
                          descriptionController
                              .text
                              .trim();
                    });

                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text(
                    'Save Changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
Future<void> regenerateName() async {
  try {
    setState(() {
      isGenerating = true;
    });

    final result =
        await OpenAIService()
            .generateBrandName(
      description,
    );

    setState(() {
      brandName = result;
    });
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
Future<void>
regenerateTagline() async {
  try {
    final result =
        await OpenAIService()
            .generateTagline(
      description,
    );

    setState(() {
      tagline = result;
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(e.toString()),
      ),
    );
  }
}
Future<void>
improveDescription() async {
  try {
    final result =
        await OpenAIService()
            .generateDescription(
      description,
    );

    setState(() {
      description = result;
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(e.toString()),
      ),
    );
  }
}
  Future<void> saveBrand() async {
  try {
    setState(() {
      isSaving = true;
    });

    final updatedBrand =
        GeneratedBrandModel(
      brandName: brandName,
      tagline: tagline,
      description: description,
      colors: colors,
      personalityTraits:
          personality,
      targetAudience:
          audience,
      brandScore:
          widget.brand.brandScore,
    );

    await BrandService()
        .saveGeneratedBrand(
      updatedBrand,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Brand Saved Successfully',
        ),
      ),
    );

    context.go(
      '/seller-dashboard',
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
        isSaving = false;
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
          'AI Brand Studio',
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
  children: [

    Expanded(
      child: Text(
        brandName,
        style:
            const TextStyle(
          fontSize: 32,
          color: Colors.white,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    ),

    TextButton(
      onPressed:
          regenerateName,
      child: const Text(
        'Try Another',
      ),
    ),
  ],
),

            const SizedBox(
              height: 8,
            ),

            Row(
  children: [

    Expanded(
      child: Text(
        tagline,
        style:
            const TextStyle(
          fontSize: 18,
          color: Colors.white70,
        ),
      ),
    ),

    TextButton(
      onPressed:
          regenerateTagline,
      child: const Text(
        'Try Another',
      ),
    ),
  ],
),

            const SizedBox(
              height: 24,
            ),

            BrandScoreCard(
              score:
                  widget.brand.brandScore,
            ),

            const SizedBox(
              height: 30,
            ),

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                    color: Colors.white,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Column(
  crossAxisAlignment:
      CrossAxisAlignment.start,
  children: [

    Align(
      alignment:
          Alignment.centerRight,
      child: TextButton(
        onPressed:
            improveDescription,
        child: const Text(
          'Improve',
        ),
      ),
    ),

    Text(
      description,
      style: TextStyle(
        color: Colors.white
            .withOpacity(0.9),
      ),
    ),
  ],
),

            const SizedBox(
              height: 30,
            ),

            const Text(
              'Brand Colors',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                    color: Colors.white,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors
                  .map(
                    (color) => Chip(
                      label: Text(
                        color,
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(
              height: 30,
            ),

            const Text(
              'Target Audience',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                    color: Colors.white,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: audience
                  .map(
                    (item) => Chip(
                      label: Text(
                        item,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(
              height: 30,
            ),

            const Text(
              'Brand Personality',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                    color: Colors.white,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: personality
                  .map(
                    (trait) => Chip(
                      label: Text(
                        trait,
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
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  context.push(
                    '/ai-logo-generation',
                    extra:
                        widget.brand,
                  );
                },
                child: const Text(
                  'Generate Logos',
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: editBrand,
    icon: const Icon(
      Icons.edit,
    ),
    label: const Text(
      'Edit Brand',
    ),
  ),
),
const SizedBox(height: 12),
            SizedBox(
              width:
                  double.infinity,
              height: 55,
              child:
                  OutlinedButton(
                onPressed:
                    isSaving
                        ? null
                        : saveBrand,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(),
                      )
                    : const Text(
                        'Save Brand',
                      ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            SizedBox(
              width:
                  double.infinity,
              height: 55,
              child:
                  OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'AI Listing Generator coming next.',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Generate First Listing',
                ),
              ),
            ),

            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}